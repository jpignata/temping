# Temping

Temping is used to create temporary table-backed ActiveRecord models for use in tests.

    include Temping
    
    before(:all) do
      create_model :posts do
        with_columns do |table|
          table.string :headline
          table.text :body
          table.integer :view_count
        end

        validates_presence_of :headline
        
        def popular?
          view_count > 100
        end
      end
    end
    
    describe "#popular" do
      context "when a post is view_count over 100 times" do
        it "returns true" do
          post = Post.create! do |p|
            p.headline = "Headline"
            p.view_count = 200
          end
          
          post.should be_popular
        end
      end
        
    end
    
This is especially useful if testing an ActiveRecord plugin or a module used in a Rails application to decouple your module's tests from a concrete implementation.
  
    include Temping
    
    before(:all) do
      create_model :posts do
        include HasArticles
      end
    end
    
    describe "HasArticles tests"...