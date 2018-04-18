# coding: utf-8
require File.join(File.dirname(__FILE__), "/spec_helper")

describe Temping do
  describe ".create" do
    it "creates and returns an ActiveRecord model" do
      post_class = Temping.create(:post)
      expect(post_class).to eq Post
      expect(post_class.table_name).to eq "posts"
      expect(post_class.primary_key).to eq "id"
    end

    context "when the ActiveRecord major version is less than 5" do
      before { stub_const("ActiveRecord::VERSION::MAJOR", 4) }

      it "creates a model that inherits from ActiveRecord::Base" do
        puppy_class = Temping.create(:puppy)
        expect(puppy_class.superclass).to eq(ActiveRecord::Base)
      end
    end

    context "when the ActiveRecord major version is greater than 4" do
      before { stub_const("ActiveRecord::VERSION::MAJOR", 5) }

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
      it 'uses the provided parent class option' do
        child_class = Temping.create(:test_child, parent_class: TestBaseClass)
        expect(child_class.superclass).to eq(TestBaseClass)
        expect(child_class.new).to be_an(TestBaseClass)
      end
      it 'doesn’t affect other types' do
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

    describe ".with_columns" do
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

      it "resets column information" do
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

    describe ".teardown" do
      it "undefines the models" do
        Temping.create :user do
          with_columns do |table|
            table.string :email
          end
        end

        # Store the connection because a call to teardown will undefine the
        # User model.
        connection = User.connection

        Temping.teardown

        expect(connection.temporary_table_exists?(:users)).to be_falsey
        expect(Object.const_defined?(:User)).to be_falsey
      end

      it 'clears the reflections cache' do
        Temping.create :user do
          has_many :posts
        end

        Temping.create :posts do
          with_columns do |table|
            table.references :user
          end
        end

        User.joins(:posts).to_a

        AUTOLOADABLE_CONSTANT
        expect { Temping.teardown }.not_to change { defined?(AUTOLOADABLE_CONSTANT) }

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

      context "when foreign key constraints exist" do
        before do
          Temping.create(:containers)
          Temping.create(:items) do
            with_columns do |t|
              t.references :container, foreign_key: true
            end
          end
        end

        it "undefines the models" do
          expect { Temping.teardown }.not_to raise_error
        end
      end
    end

    describe ".cleanup" do
      before :all do
        Temping.create(:user)
      end

      it "destroys all models" do
        expect do
          Temping.cleanup
        end.not_to change { defined?(User) }
      end

      it "keeps constans and tables" do
        User.create!

        expect do
          Temping.cleanup
        end.to change { User.count }.from(1).to(0)
      end
    end
  end
end
