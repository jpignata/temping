require File.join(File.dirname(__FILE__), "/spec_helper")

TABLE_NOT_EXISTS_REGEX = Regexp.new(
  "(Could not find table)|(Table .+? doesn't exist)|(relation .+? does not exist)",
  Regexp::IGNORECASE
)

describe Temping do
  let(:is_mysql_or_sqlite) do
    %w[mysql sqlite].any? do |name|
      ActiveRecord::Base.connection.adapter_name.downcase.starts_with?(name)
    end
  end

  after { Temping.teardown }

  describe ".create" do
    it "creates and returns an ActiveRecord model" do
      post_class = Temping.create(:post)
      expect(post_class).to eq Post
      expect(post_class.table_name).to eq "posts"
      expect(post_class.primary_key).to eq "id"
    end

    it "allows creating records" do
      Temping.create(:post)
      expect { Post.create! }.to change { Post.count }.from(0).to(1)
    end

    context "when ApplicationRecord is defined" do
      before do
        unless defined?(ApplicationRecord)
          class ApplicationRecord < ActiveRecord::Base; end
        end
      end

      it "creates a model that inherits from ApplicationRecord" do
        kitty_class = Temping.create(:kittens)
        expect(kitty_class.superclass).to eq ApplicationRecord
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
        expect(gerbil_class.superclass).to eq ActiveRecord::Base
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

      after { Object.send(:remove_const, :TestBaseClass) }

      it "uses the provided parent class option" do
        child_class = Temping.create(:test_child, parent_class: TestBaseClass)
        expect(child_class.superclass).to eq TestBaseClass
        expect(child_class.new).to be_a TestBaseClass
      end

      it "doesn’t affect other types" do
        gerbil_class = Temping.create(:gerbil)
        expect(gerbil_class.superclass).to eq ActiveRecord::Base
      end
    end

    context "with a one level namespace" do
      subject { Temping.create("people/developers") }

      it "creates a model with the correct namespace" do
        expect(subject.new).to be_a People::Developer
      end

      it "creates a table with the correct name" do
        developer_class = subject
        expect(developer_class.table_name).to eq "developers"
        expect(developer_class.primary_key).to eq "id"
        expect(ActiveRecord::Base.connection.column_exists?(:developers, :id)).to eq true
      end

      it "allows creating records" do
        subject
        expect { People::Developer.create! }.to change { People::Developer.count }.from(0).to(1)
      end
    end

    context "with a deep namespace" do
      subject { Temping.create(:"virtual_object/feeling/emotional/happiness") }

      it "creates a model with the correct namespace" do
        expect(subject.new).to be_a VirtualObject::Feeling::Emotional::Happiness
      end

      it "creates a table with the correct name" do
        expect(subject.table_name).to eq "happinesses"
        expect(subject.primary_key).to eq "id"
        expect(ActiveRecord::Base.connection.column_exists?(:happinesses, :id)).to eq true
      end

      it "allows creating records" do
        subject
        expect { VirtualObject::Feeling::Emotional::Happiness.create! }
          .to change { VirtualObject::Feeling::Emotional::Happiness.count }.from(0).to(1)
      end
    end

    context "with a deep namespace, predefined modules, and table prefix" do
      subject { Temping.create(:"physical_object/vehicle/car/sedan") }

      around do |example|
        Object.const_set(:PhysicalObject, Module.new)
        PhysicalObject.const_set(:Vehicle, Module.new)
        PhysicalObject::Vehicle.const_set(:Car, Module.new do
          def self.table_name_prefix
            "custom_prefix_"
          end
        end)
        example.run
        PhysicalObject::Vehicle.send(:remove_const, :Car)
        PhysicalObject.send(:remove_const, :Vehicle)
        Object.send(:remove_const, :PhysicalObject)
      end

      it "creates a model with the correct namespace" do
        expect(subject.new).to be_a PhysicalObject::Vehicle::Car::Sedan
      end

      it "creates a table with the correct name" do
        expect(subject.table_name).to eq "custom_prefix_sedans"
        expect(subject.primary_key).to eq "id"
        expect(ActiveRecord::Base.connection.column_exists?(:custom_prefix_sedans, :id)).to eq true
      end
    end

    it "creates table with given options" do
      mushroom_class = Temping.create(:mushroom, primary_key: :guid)
      expect(mushroom_class.table_name).to eq "mushrooms"
      expect(mushroom_class.primary_key).to eq "guid"
    end

    it "evaluates block in the model's context" do
      Temping.create(:publication) do
        with_columns do |t|
          t.string :name
        end
        validates :name, presence: true
      end

      publication = Publication.new
      expect(publication).to_not be_valid
      expect(publication.errors.full_messages).to include "Name can't be blank"
      publication.name = "The New York Times"
      expect(publication).to be_valid
    end

    it "silently skips initialization if the constant is already defined" do
      expect { 2.times { Temping.create(:dog) } }.not_to raise_exception
    end

    it "returns the model if the constant is already defined" do
      cat = Temping.create(:cat)
      expect(Temping.create(:cat)).to eq cat
    end

    describe "with_columns" do
      it "creates columns passed in through a block" do
        Temping.create(:comment) do
          with_columns do |t|
            t.integer :count
            t.string :headline
            t.text :body
          end
        end

        expect(Comment.columns.map(&:name)).to include "count", "headline", "body"
      end

      it "adds new columns if called more than once" do
        Temping.create(:human) do
          with_columns do |t|
            t.integer :head_count
          end
        end

        expect(Human.columns.map(&:name)).to include "head_count"

        Temping.create(:human) do
          with_columns do |t|
            t.string :name
            t.text :body
          end
        end

        expect(Human.columns.map(&:name)).to include "name", "body"
      end
    end
  end

  describe ".teardown" do
    subject { Temping.teardown }

    context "with a single model" do
      before do
        Temping.create(:user) do
          with_columns do |t|
            t.string :email
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

    context "with a single model in a one level namespace" do
      before do
        Temping.create(:"animal/dog") do
          with_columns do |t|
            t.string :name
          end
        end
        Animal::Dog.create!
      end

      it "undefines the model, module, and deletes the table" do
        expect(Object.const_defined?(:Animal)).to eq true
        expect(Object.const_defined?("Animal::Dog")).to eq true
        expect(ActiveRecord::Base.connection.column_exists?(:dogs, :id)).to eq true
        subject
        expect(Object.const_defined?(:Animal)).to eq false
        expect(Object.const_defined?("Animal::Dog")).to eq false
        expect { ActiveRecord::Base.connection.column_exists?(:dogs, :id) }
          .to raise_error ActiveRecord::StatementInvalid, TABLE_NOT_EXISTS_REGEX
      end
    end

    context "with a single model in a deep namespace" do
      before { Temping.create("animal/big/medium_to_large/dog") }

      it "undefines the model, modules, and deletes the table" do
        expect(Object.const_defined?(:Animal)).to eq true
        expect(Object.const_defined?("Animal::Big")).to eq true
        expect(Object.const_defined?("Animal::Big::MediumToLarge")).to eq true
        expect(Object.const_defined?("Animal::Big::MediumToLarge::Dog")).to eq true
        expect(ActiveRecord::Base.connection.column_exists?(:dogs, :id)).to eq true
        subject
        expect(Object.const_defined?(:Animal)).to eq false
        expect(Object.const_defined?("Animal::Big")).to eq false
        expect(Object.const_defined?("Animal::Big::MediumToLarge")).to eq false
        expect(Object.const_defined?("Animal::Big::MediumToLarge::Dog")).to eq false
        expect { ActiveRecord::Base.connection.column_exists?(:dogs, :id) }
          .to raise_error ActiveRecord::StatementInvalid, TABLE_NOT_EXISTS_REGEX
      end
    end

    context "with two models and references" do
      before do
        Temping.create(:user) do
          has_many :posts
        end
        Temping.create(:posts) do
          with_columns do |t|
            t.references :user
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

        Temping.create(:user) do
          has_many :posts
          has_many :comments, through: :posts
        end
        Temping.create(:posts) do
          with_columns do |t|
            t.references :user
          end
          has_many :comments
        end
        Temping.create(:comments) do
          with_columns do |t|
            t.references :post
          end
        end

        expect { User.joins(:comments).to_a }.not_to raise_error
      end
    end

    context "with three models sharing module-based namespaces" do
      before do
        Temping.create("colors/reddish/orange")
        Temping.create("colors/reddish/red")
      end

      it "undefines the model, modules, and deletes the table" do
        expect(Object.const_defined?(:Colors)).to eq true
        expect(Object.const_defined?("Colors::Reddish")).to eq true
        expect(Object.const_defined?("Colors::Reddish::Orange")).to eq true
        expect(Object.const_defined?("Colors::Reddish::Red")).to eq true
        expect(ActiveRecord::Base.connection.column_exists?(:oranges, :id)).to eq true
        expect(ActiveRecord::Base.connection.column_exists?(:reds, :id)).to eq true
        subject
        expect(Object.const_defined?(:Colors)).to eq false
        expect(Object.const_defined?("Colors::Reddish")).to eq false
        expect(Object.const_defined?("Colors::Reddish::Orange")).to eq false
        expect(Object.const_defined?("Colors::Reddish::Red")).to eq false
        expect { ActiveRecord::Base.connection.column_exists?(:oranges, :id) }
          .to raise_error ActiveRecord::StatementInvalid, TABLE_NOT_EXISTS_REGEX
        expect { ActiveRecord::Base.connection.column_exists?(:reds, :id) }
          .to raise_error ActiveRecord::StatementInvalid, TABLE_NOT_EXISTS_REGEX
      end
    end

    context "with four models sharing class-based namespaces" do
      before do
        Temping.create("items/computer")
        Temping.create("items/computer/mac")
        Temping.create("items/computer/linux")
        Temping.create("items/chair")
      end

      it "undefines the model, modules, and deletes the table" do
        expect(Object.const_defined?(:Items)).to eq true
        expect(Object.const_defined?("Items::Computer")).to eq true
        expect(Object.const_defined?("Items::Computer::Mac")).to eq true
        expect(Object.const_defined?("Items::Computer::Linux")).to eq true
        expect(Object.const_defined?("Items::Chair")).to eq true
        expect(ActiveRecord::Base.connection.column_exists?(:computers, :id)).to eq true
        expect(ActiveRecord::Base.connection.column_exists?(:computer_macs, :id)).to eq true
        expect(ActiveRecord::Base.connection.column_exists?(:computer_linuxes, :id)).to eq true
        expect(ActiveRecord::Base.connection.column_exists?(:chairs, :id)).to eq true
        subject
        expect(Object.const_defined?(:Items)).to eq false
        expect(Object.const_defined?("Items::Computer")).to eq false
        expect(Object.const_defined?("Items::Computer::Mac")).to eq false
        expect(Object.const_defined?("Items::Computer::Linux")).to eq false
        expect(Object.const_defined?("Items::Chair")).to eq false
        expect { ActiveRecord::Base.connection.column_exists?(:computers, :id) }
          .to raise_error ActiveRecord::StatementInvalid, TABLE_NOT_EXISTS_REGEX
        expect { ActiveRecord::Base.connection.column_exists?(:computer_macs, :id) }
          .to raise_error ActiveRecord::StatementInvalid, TABLE_NOT_EXISTS_REGEX
        expect { ActiveRecord::Base.connection.column_exists?(:computer_linuxes, :id) }
          .to raise_error ActiveRecord::StatementInvalid, TABLE_NOT_EXISTS_REGEX
        expect { ActiveRecord::Base.connection.column_exists?(:chairs, :id) }
          .to raise_error ActiveRecord::StatementInvalid, TABLE_NOT_EXISTS_REGEX
      end
    end

    context "with four models, references, and foreign keys" do
      # MySQL and SQLite don't allow setting foreign keys for temporary tables
      let(:options) { is_mysql_or_sqlite ? {temporary: false} : {} }

      before do
        Temping.create(:user, options) do
          has_many :posts
          has_many :comments, through: :posts
          has_many :ratings
        end
        Temping.create(:posts, options) do
          with_columns do |t|
            t.references :user, foreign_key: true
          end
          belongs_to :user
          has_many :comments
        end
        Temping.create(:comments, options) do
          with_columns do |t|
            t.references :post, foreign_key: true
          end
          belongs_to :post
        end
        Temping.create(:ratings, options) do
          with_columns do |t|
            t.references :user, foreign_key: true
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

    context "with four models, references, foreign keys, deep namespaces, and table prefix" do
      # MySQL and SQLite don't allow setting foreign keys for temporary tables
      let(:options) { is_mysql_or_sqlite ? {temporary: false} : {} }

      before do
        Temping.create(:world)
        # This syntax is on purpose, to test how it handles modules defined this way.
        # standard:disable Lint/ConstantDefinitionInBlock, Layout/EmptyLineBetweenDefs
        module World::Continent; end
        module World::Continent::Country
          def self.table_name_prefix
            "territories_"
          end
        end
        module Establishments; end
        module Establishments::Shops; end
        # standard:enable Lint/ConstantDefinitionInBlock, Layout/EmptyLineBetweenDefs
        Temping.create("world/continent/country/cities", options) do
          has_many :streets
          has_many :buildings, through: :streets
          has_many :groceries
        end
        Temping.create(:streets, options) do
          with_columns do |t|
            t.references :territories_city, foreign_key: true
          end
          belongs_to :city
          has_many :buildings
        end
        Temping.create(:buildings, options) do
          with_columns do |t|
            t.references :street, foreign_key: true
          end
          belongs_to :street
        end
        Temping.create("establishments/shops/groceries", options) do
          with_columns do |t|
            t.references :territories_city, foreign_key: true
          end
          belongs_to :city
        end
      end

      after do
        Establishments.send(:remove_const, :Shops)
        Object.send(:remove_const, :Establishments)
      end

      it "undefines the models, modules created by Temping, and deletes the tables" do
        expect(Object.const_defined?(:World)).to eq true
        expect(Object.const_defined?("World::Continent")).to eq true
        expect(Object.const_defined?("World::Continent::Country")).to eq true
        expect(Object.const_defined?("World::Continent::Country::City")).to eq true
        expect(Object.const_defined?(:Street)).to eq true
        expect(Object.const_defined?(:Building)).to eq true
        expect(Object.const_defined?(:Establishments)).to eq true
        expect(Object.const_defined?("Establishments::Shops")).to eq true
        expect(Object.const_defined?("Establishments::Shops::Grocery")).to eq true
        expect(ActiveRecord::Base.connection.column_exists?(:worlds, :id)).to eq true
        expect(ActiveRecord::Base.connection.column_exists?(:territories_cities, :id)).to eq true
        expect(ActiveRecord::Base.connection.column_exists?(:streets, :id)).to eq true
        expect(ActiveRecord::Base.connection.column_exists?(:buildings, :id)).to eq true
        expect(ActiveRecord::Base.connection.column_exists?(:groceries, :id)).to eq true
        subject
        expect(Object.const_defined?(:World)).to eq false
        expect(Object.const_defined?("World::Continent")).to eq false
        expect(Object.const_defined?("World::Continent::Country")).to eq false
        expect(Object.const_defined?("World::Continent::Country::City")).to eq false
        expect(Object.const_defined?(:Street)).to eq false
        expect(Object.const_defined?(:Building)).to eq false
        expect(Object.const_defined?(:Establishments)).to eq true
        expect(Object.const_defined?("Establishments::Shops")).to eq true
        expect(Object.const_defined?("Establishments::Shops::Grocery")).to eq false
        expect { ActiveRecord::Base.connection.column_exists?(:worlds, :id) }
          .to raise_error ActiveRecord::StatementInvalid, TABLE_NOT_EXISTS_REGEX
        expect { ActiveRecord::Base.connection.column_exists?(:territories_cities, :id) }
          .to raise_error ActiveRecord::StatementInvalid, TABLE_NOT_EXISTS_REGEX
        expect { ActiveRecord::Base.connection.column_exists?(:streets, :id) }
          .to raise_error ActiveRecord::StatementInvalid, TABLE_NOT_EXISTS_REGEX
        expect { ActiveRecord::Base.connection.column_exists?(:buildings, :id) }
          .to raise_error ActiveRecord::StatementInvalid, TABLE_NOT_EXISTS_REGEX
        expect { ActiveRecord::Base.connection.column_exists?(:groceries, :id) }
          .to raise_error ActiveRecord::StatementInvalid, TABLE_NOT_EXISTS_REGEX
      end
    end
  end

  describe ".cleanup" do
    subject { Temping.cleanup }

    context "with a single model" do
      before do
        Temping.create(:user) do
          with_columns do |t|
            t.string :email
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

    context "with two models, namespaces, references, and foreign key" do
      # MySQL and SQLite don't allow setting foreign keys for temporary tables
      let(:options) { is_mysql_or_sqlite ? {temporary: false} : {} }

      before do
        Temping.create("stuff/user", options)
        Temping.create("stuff/post", options) do
          with_columns do |t|
            t.references :user, foreign_key: true
          end
          belongs_to :user, optional: false
        end
      end

      it "keeps constants" do
        expect(Object.const_defined?(:Stuff)).to eq true
        expect(Object.const_defined?("Stuff::User")).to eq true
        expect(Object.const_defined?("Stuff::Post")).to eq true
        subject
        expect(Object.const_defined?(:Stuff)).to eq true
        expect(Object.const_defined?("Stuff::User")).to eq true
        expect(Object.const_defined?("Stuff::Post")).to eq true
      end

      it "keeps tables" do
        expect(ActiveRecord::Base.connection.column_exists?(:users, :id)).to eq true
        expect(ActiveRecord::Base.connection.column_exists?(:posts, :id)).to eq true
        subject
        expect(ActiveRecord::Base.connection.column_exists?(:users, :id)).to eq true
        expect(ActiveRecord::Base.connection.column_exists?(:posts, :id)).to eq true
      end

      it "destroys records" do
        user = Stuff::User.create!
        Stuff::Post.create!(user: user)
        expect { subject }
          .to change { Stuff::User.count }.from(1).to(0)
          .and change { Stuff::Post.count }.from(1).to(0)
      end
    end
  end
end
