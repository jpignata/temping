require File.join(File.dirname(__FILE__), "/spec_helper")

TABLE_NOT_EXISTS_REGEX = Regexp.new(
  "(Could not find table)|(Table .+? doesn't exist)|(relation .+? does not exist)",
  Regexp::IGNORECASE
)

describe Temping do
  after { Temping.teardown }

  let(:is_mysql_or_sqlite) do
    %w[mysql sqlite].any? do |name|
      ActiveRecord::Base.connection.adapter_name.downcase.starts_with?(name)
    end
  end

  describe ".create" do
    it "creates and returns an ActiveRecord model" do
      post_class = Temping.create(:post)
      expect(post_class).to eq Post
      expect(post_class.table_name).to eq "posts"
      expect(post_class.primary_key).to eq "id"
    end

    context "when ApplicationRecord is defined" do
      before do
        unless defined?(ApplicationRecord)
          class ApplicationRecord < ActiveRecord::Base; end
        end
      end

      it "creates a model that inherits from ApplicationRecord" do
        kitty_class = Temping.create(:kittens)
        expect(kitty_class.superclass).to eq(ApplicationRecord)
      end
    end

    context "when ApplicationRecord is not defined" do
      before do
        if defined?(ApplicationRecord)
          Object.send(:remove_const, :ApplicationRecord)
        end
      end

      it "creates a model that inherits from ActiveRecord::Base" do
        gerbil_class = Temping.create(:gerbil)
        expect(gerbil_class.superclass).to eq(ActiveRecord::Base)
      end
    end

    context "with a custom parent class" do
      before do
        unless defined?(TestBaseClass)
          class TestBaseClass < ActiveRecord::Base
            self.abstract_class = true
          end
        end
      end

      after do
        Object.send(:remove_const, :TestBaseClass)
      end

      it "uses the provided parent class option" do
        child_class = Temping.create(:test_child, parent_class: TestBaseClass)
        expect(child_class.superclass).to eq(TestBaseClass)
        expect(child_class.new).to be_an(TestBaseClass)
      end

      it "doesn’t affect other types" do
        gerbil_class = Temping.create(:gerbil)
        expect(gerbil_class.superclass).to eq(ActiveRecord::Base)
      end
    end

    it "creates table with given options" do
      mushroom_class = Temping.create(:mushroom, primary_key: :guid)
      expect(mushroom_class.table_name).to eq "mushrooms"
      expect(mushroom_class.primary_key).to eq "guid"
    end

    it "evaluates block in the model's context" do
      Temping.create :publication do
        with_columns do |table|
          table.string :name
        end

        validates :name, presence: true
      end

      publication = Publication.new
      expect(publication).to_not be_valid
      expect(publication.errors.full_messages).to include("Name can't be blank")
      publication.name = "The New York Times"
      expect(publication).to be_valid
    end

    it "silently skips initialization if the constant is already defined" do
      expect {
        2.times { Temping.create :dog }
      }.not_to raise_exception
    end

    it "returns the model if the constant is already defined" do
      cat = Temping.create(:cat)

      expect(Temping.create(:cat)).to eq cat
    end

    describe "with_columns" do
      it "creates columns passed in through a block" do
        Temping.create :comment do
          with_columns do |table|
            table.integer :count
            table.string :headline
            table.text :body
          end
        end

        expect(Comment.columns.map(&:name)).to include("count", "headline", "body")
      end

      it "adds new columns if called more than once" do
        Temping.create :human do
          with_columns do |table|
            table.integer :head_count
          end
        end

        expect(Human.columns.map(&:name)).to include("head_count")

        Temping.create :human do
          with_columns do |table|
            table.string :name
            table.text :body
          end
        end

        expect(Human.columns.map(&:name)).to include("name", "body")
      end
    end
  end

  describe ".teardown" do
    subject { Temping.teardown }

    context "with a single model" do
      before do
        Temping.create :user do
          with_columns do |table|
            table.string :email
          end
        end
        User.create!
      end

      it "undefines the model and deletes the table" do
        expect(Object.const_defined?(:User)).to eq true
        expect(ActiveRecord::Base.connection.column_exists?(:users, :id)).to eq true
        subject
        expect(Object.const_defined?(:User)).to eq false
        expect { ActiveRecord::Base.connection.column_exists?(:users, :id) }
          .to raise_error ActiveRecord::StatementInvalid, TABLE_NOT_EXISTS_REGEX
      end

      it "does not raise errors if called more than once" do
        expect { 2.times { subject } }.not_to raise_error
      end
    end

    context "with two models and references" do
      before do
        Temping.create :user do
          has_many :posts
        end
        Temping.create :posts do
          with_columns do |table|
            table.references :user
          end
        end
        User.joins(:posts).to_a
      end

      it "clears the reflections cache allowing to re-create the models" do
        if ActiveRecord::VERSION::MAJOR < 7
          expect { AUTOLOADABLE_CONSTANT }.not_to raise_error
          expect { subject }.not_to change { defined?(AUTOLOADABLE_CONSTANT) }
        else
          subject
        end

        Temping.create :user do
          has_many :posts
          has_many :comments, through: :posts
        end
        Temping.create :posts do
          with_columns do |table|
            table.references :user
          end
          has_many :comments
        end
        Temping.create :comments do
          with_columns do |table|
            table.references :post
          end
        end

        expect { User.joins(:comments).to_a }.not_to raise_error
      end
    end

    context "with four models, references, and foreign keys" do
      # MySQL and SQLite don't allow setting foreign keys for temporary tables
      let(:options) { is_mysql_or_sqlite ? {temporary: false} : {} }

      before do
        Temping.create :user, options do
          has_many :posts
          has_many :comments, through: :posts
          has_many :ratings
        end
        Temping.create :posts, options do
          with_columns do |table|
            table.references :user, foreign_key: true
          end
          belongs_to :user
          has_many :comments
        end
        Temping.create :comments, options do
          with_columns do |table|
            table.references :post, foreign_key: true
          end
          belongs_to :post
        end
        Temping.create :ratings, options do
          with_columns do |table|
            table.references :user, foreign_key: true
          end
          belongs_to :user
        end
      end

      it "undefines the models and deletes the tables" do
        expect(Object.const_defined?(:User)).to eq true
        expect(Object.const_defined?(:Post)).to eq true
        expect(Object.const_defined?(:Comment)).to eq true
        expect(Object.const_defined?(:Rating)).to eq true
        expect(ActiveRecord::Base.connection.column_exists?(:users, :id)).to eq true
        expect(ActiveRecord::Base.connection.column_exists?(:posts, :id)).to eq true
        expect(ActiveRecord::Base.connection.column_exists?(:comments, :id)).to eq true
        expect(ActiveRecord::Base.connection.column_exists?(:ratings, :id)).to eq true
        subject
        expect(Object.const_defined?(:User)).to eq false
        expect(Object.const_defined?(:Post)).to eq false
        expect(Object.const_defined?(:Comment)).to eq false
        expect(Object.const_defined?(:Rating)).to eq false
        expect { ActiveRecord::Base.connection.column_exists?(:users, :id) }
          .to raise_error ActiveRecord::StatementInvalid, TABLE_NOT_EXISTS_REGEX
        expect { ActiveRecord::Base.connection.column_exists?(:posts, :id) }
          .to raise_error ActiveRecord::StatementInvalid, TABLE_NOT_EXISTS_REGEX
        expect { ActiveRecord::Base.connection.column_exists?(:comments, :id) }
          .to raise_error ActiveRecord::StatementInvalid, TABLE_NOT_EXISTS_REGEX
        expect { ActiveRecord::Base.connection.column_exists?(:ratings, :id) }
          .to raise_error ActiveRecord::StatementInvalid, TABLE_NOT_EXISTS_REGEX
      end
    end
  end

  describe ".cleanup" do
    subject { Temping.cleanup }

    context "with a single model" do
      before do
        Temping.create :user do
          with_columns do |table|
            table.string :email
          end
        end
      end

      it "keeps constants" do
        expect(Object.const_defined?(:User)).to eq true
        subject
        expect(Object.const_defined?(:User)).to eq true
      end

      it "keeps tables" do
        expect(ActiveRecord::Base.connection.column_exists?(:users, :id)).to eq true
        subject
        expect(ActiveRecord::Base.connection.column_exists?(:users, :id)).to eq true
      end

      it "destroys records" do
        User.create!
        expect { subject }.to change { User.count }.from(1).to(0)
      end
    end

    context "with two models, references, and foreign key" do
      # MySQL and SQLite don't allow setting foreign keys for temporary tables
      let(:options) { is_mysql_or_sqlite ? {temporary: false} : {} }

      before do
        Temping.create(:user, options)
        Temping.create(:post, options) do
          with_columns do |table|
            table.references :user, foreign_key: true
          end
          belongs_to :user, optional: false
        end
      end

      it "keeps constants" do
        expect(Object.const_defined?(:User)).to eq true
        expect(Object.const_defined?(:Post)).to eq true
        subject
        expect(Object.const_defined?(:User)).to eq true
        expect(Object.const_defined?(:Post)).to eq true
      end

      it "keeps tables" do
        expect(ActiveRecord::Base.connection.column_exists?(:users, :id)).to eq true
        expect(ActiveRecord::Base.connection.column_exists?(:posts, :id)).to eq true
        subject
        expect(ActiveRecord::Base.connection.column_exists?(:users, :id)).to eq true
        expect(ActiveRecord::Base.connection.column_exists?(:posts, :id)).to eq true
      end

      it "destroys records" do
        user = User.create!
        Post.create!(user: user)
        expect { subject }
          .to change { User.count }.from(1).to(0).and change { Post.count }.from(1).to(0)
      end
    end
  end
end
