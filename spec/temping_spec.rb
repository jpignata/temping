require File.join(File.dirname(__FILE__), "/spec_helper")

describe Temping do
  describe ".create" do
    it "creates and returns an ActiveRecord model" do
      post_class = Temping.create(:post)
      expect(post_class.ancestors).to include(ActiveRecord::Base)
      expect(post_class).to eq Post
      expect(post_class.table_name).to eq "posts"
      expect(post_class.connection.primary_key(:posts)).to eq "id"
    end

    it "creates table with given options" do
      mushroom_class = Temping.create(:mushroom, primary_key: :guid)
      expect(mushroom_class.table_name).to eq "mushrooms"
      expect(mushroom_class.connection.primary_key(:mushrooms)).to eq "guid"
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
    end

  end
end
