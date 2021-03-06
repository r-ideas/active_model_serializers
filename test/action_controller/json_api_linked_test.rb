require 'test_helper'

module ActionController
  module Serialization
    class JsonApiLinkedTest < ActionController::TestCase
      class MyController < ActionController::Base
        def setup_post
          @author = Author.new(id: 1, name: 'Steve K.')
          @author.posts = []
          @author2 = Author.new(id: 2, name: 'Anonymous')
          @author2.posts = []
          @post = Post.new(id: 1, title: 'New Post', body: 'Body')
          @first_comment = Comment.new(id: 1, body: 'ZOMG A COMMENT')
          @second_comment = Comment.new(id: 2, body: 'ZOMG ANOTHER COMMENT')
          @post.comments = [@first_comment, @second_comment]
          @post.author = @author
          @first_comment.post = @post
          @first_comment.author = @author2
          @second_comment.post = @post
          @second_comment.author = nil
        end

        def with_json_api_adapter
          old_adapter = ActiveModel::Serializer.config.adapter
          ActiveModel::Serializer.config.adapter = :json_api
          yield
        ensure
          ActiveModel::Serializer.config.adapter = old_adapter
        end

        def render_resource_without_include
          with_json_api_adapter do
            setup_post
            render json: @post
          end
        end

        def render_resource_with_include
          with_json_api_adapter do
            setup_post
            render json: @post, include: 'author'
          end
        end

        def render_resource_with_nested_include
          with_json_api_adapter do
            setup_post
            render json: @post, include: 'comments.author'
          end
        end

        def render_collection_without_include
          with_json_api_adapter do
            setup_post
            render json: [@post]
          end
        end

        def render_collection_with_include
          with_json_api_adapter do
            setup_post
            render json: [@post], include: 'author,comments'
          end
        end
      end

      tests MyController

      def test_render_resource_without_include
        get :render_resource_without_include
        response = JSON.parse(@response.body)
        refute response.key? 'linked'
      end

      def test_render_resource_with_include
        get :render_resource_with_include
        response = JSON.parse(@response.body)
        assert response.key? 'linked'
        assert_equal 1, response['linked']['authors'].size
        assert_equal 'Steve K.', response['linked']['authors'].first['name']
      end

      def test_render_resource_with_nested_include
        get :render_resource_with_nested_include
        response = JSON.parse(@response.body)
        assert response.key? 'linked'
        assert_equal 1, response['linked']['authors'].size
        assert_equal 'Anonymous', response['linked']['authors'].first['name']
      end

      def test_render_collection_without_include
        get :render_collection_without_include
        response = JSON.parse(@response.body)
        refute response.key? 'linked'
      end

      def test_render_collection_with_include
        get :render_collection_with_include
        response = JSON.parse(@response.body)
        assert response.key? 'linked'
      end
    end
  end
end
