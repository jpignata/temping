require File.join(File.dirname(__FILE__), "/spec_helper")

describe Temping do
  describe "#Temping.create_model" do
    it "creates and returns an AR::Base-derived model" do
      post_class = Temping.create_model :post
      post_class.ancestors.should include(ActiveRecord::Base)
      post_class.should == Post
      post_class.table_name.should == "posts"
    end

    it "evals all statements passed in through a block" do
      Temping.create_model :publication do
        with_columns do |table|
          table.string :name
        end

        validates_presence_of :name
      end

      publication = Publication.new
      publication.should_not be_valid
      publication.errors.full_messages.should include("Name can't be blank")
      publication.name = "The New York Times"
      publication.should be_valid
    end

    it "silently skips initialization if a const is already defined" do
      lambda { 2.times { Temping.create_model :dog } }.should_not raise_error
    end

    it "returns nil if a const is already defined" do
      Temping.create_model :cat
      Temping.create_model(:cat).should be_nil
    end

    describe ".with_columns" do
      it "creates columns passed in through a block" do
        Temping.create_model :comment do
          with_columns do |table|
            table.integer :count
            table.string :headline
            table.text :body
          end
        end

        Comment.columns.map(&:name).should include("count", "headline", "body")
      end
    end
  end
end
