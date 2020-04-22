# frozen_string_literal: true

require 'minitest/autorun'
require 'rails5_xhr_update'

class FormatToAsTest < MiniTest::Test
  def test_get
    source = convert <<~RB
      def get
        get :images_path, format: :x
      end
    RB
    assert_includes(source, 'get :images_path, as: :x')
  end

  def test_post_with_keyword_as
    source = convert <<~RB
      def post
        post :image_path, as: :json
      end
    RB
    assert_includes(source, 'post :image_path, as: :json')
  end

  def test_post_with_keyword_argument__params
    source = convert <<~RB
      def post
        post :image_path, params: { id: 1, format: :x }
      end
    RB
    assert_includes(source, 'post :image_path, as: :x, params: { id: 1 }')
  end


  def test_post_with_multiple_keyword_arguments
    source = convert <<~RB
      def post
        post :image_path, params: { id: 1 }, format: :flat
      end
    RB
    assert_includes(
      source,
      'post :image_path, as: :flat, params: { id: 1 }'
    )
  end

  private

  def convert(string)
    buffer = Parser::Source::Buffer.new('simple.rb')
    buffer.raw_source = string
    Rails5XHRUpdate::FormatToAs.new.rewrite(
      buffer, Parser::CurrentRuby.new.parse(buffer)
    )
  end
end
