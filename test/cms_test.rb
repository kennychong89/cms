ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"

require_relative "../cms"

class CMSTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_index
    get "/"

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "about.txt"
  end

  def test_history_document
    get "/history.txt"

    assert_equal 200, last_response.status
    assert_equal "text/plain;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "1995 - Ruby 0.95 released."
  end

  def test_not_existent_document
    get "/illegal.txt"

    assert_equal 302, last_response.status
    get last_response["Location"]

    assert_equal 200, last_response.status
    assert_includes last_response.body, "illegal.txt does not exist."
  end

  def test_fetch_edit_page_success
    get "/history.txt/edit"

    assert_equal 200, last_response.status
    assert_includes last_response.body, "Edit content of history.txt:"
    assert_includes last_response.body, "1993 - Yukihiro Matsumoto dreams up Ruby." 
  end

  def test_fetch_edit_page_error
    get "/touch.md/edit"

    assert_equal 302, last_response.status
    get last_response["Location"]

    assert_equal 200, last_response.status
    assert_includes last_response.body, "touch.md does not exist."
  end

  def test_edit_about_txt_success
    post "/about.txt/edit", params={ :edittext => 'Post field' }

    assert_equal 302, last_response.status
    get last_response["Location"]

    assert_equal 200, last_response.status
    assert_includes last_response.body, "about.txt has been updated."

    file_path = File.expand_path("../files")
    about_file_path = file_path + "/about.txt"
    about_file_content = File.read(about_file_path)

    assert_equal "Post field", about_file_content 
  end
end