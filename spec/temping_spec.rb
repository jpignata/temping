require File.join(File.dirname(__FILE__), "/spec_helper")

describe Temping do
  include Temping

  describe ".create_model" do    
    it "creates and returns an AR::Base-derived model" do
      posts = create_model :posts
      posts.ancestors.should include(ActiveRecord::Base)
    end

    it "evals all statements passed in through a block" do
      create_model :votes do
        with_columns do |table|
          table.string :voter
        end
        
        validates_presence_of :voter
      end
      
      vote = Vote.new
      vote.should_not be_valid
      
      vote.voter = "John Pignata"
      vote.should be_valid
    end
    
    it "silently skip initialization if a const is already defined" do
      lambda { 2.times { create_model :dogs }}.should_not raise_error(Temping::ModelAlreadyDefined)
    end
    
    describe ".with_columns" do
      it "creates columns passed in through a block" do
        create_model :comments do 
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
  
  describe "database agnostism" do
    it "supports Sqlite3" do
      ActiveRecord::Base.establish_connection 'temping'
      create_model(:oranges).should == Orange
    end

    it "supports MySQL" do
      ActiveRecord::Base.establish_connection 'mysql'
      create_model(:apples).should == Apple
    end

    it "supports PostgreSQL" do
      ActiveRecord::Base.establish_connection 'postgres'
      create_model(:cherries).should == Cherry
    end
  end
end