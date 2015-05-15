require File.join(File.dirname(__FILE__), "/spec_helper")

describe Temping do
  describe ".create" do
    it "creates and returns an ActiveRecord model" do
      post_class = Temping.create(:post)
      post_class.ancestors.should include(ActiveRecord::Base)
      post_class.should == Post
      post_class.table_name.should == "posts"
    end

    it "evaluates block in the model's context" do
      Temping.create :publication do
        with_columns do |table|
          table.string :name
        end

        validates :name, presence: true
      end

      publication = Publication.new
      publication.should_not be_valid
      publication.errors.full_messages.should include("Name can't be blank")
      publication.name = "The New York Times"
      publication.should be_valid
    end

    it "silently skips initialization if the constant is already defined" do
      expect {
        2.times { Temping.create :dog }
      }.not_to raise_exception
    end

    it "returns the model if the constant is already defined" do
      cat = Temping.create(:cat)

      Temping.create(:cat).should == cat
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

        Comment.columns.map(&:name).should include("count", "headline", "body")
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

        connection.temporary_table_exists?(:users).should be_false
        Object.const_defined?(:User).should be_false
      end
    end

  end
end
