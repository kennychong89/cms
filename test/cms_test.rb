ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"
require "fileutils"
require_relative "../cms"

class CMSTest < Minitest::Test
  include Rack::Test::Methods
  
  def setup
    FileUtils.mkdir_p(data_path)
  end

  def teardown
    FileUtils.rm_rf(data_path)
  end
   
  def create_document(name, content = "")
    File.open(File.join(data_path, name), "w") do |file|
      file.write(content)
    end
  end

  def app
    Sinatra::Application
  end

  def test_index
    create_document "about.md"
    create_document "changes.txt"
    get "/"

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "about.md"
    assert_includes last_response.body, "changes.txt"
  end

  def test_history_document
    create_document "history.txt", "1995 - Ruby 0.95 released."

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
    create_document "history.txt", "1993 - Yukihiro Matsumoto dreams up Ruby."
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
    create_document "about.txt"

    post "/about.txt/edit", params={ :edittext => 'Post field' }

    assert_equal 302, last_response.status
    get last_response["Location"]

    assert_equal 200, last_response.status
    assert_includes last_response.body, "about.txt has been updated."

    about_file_path = data_path + "/about.txt"
    about_file_content = File.read(about_file_path)

    assert_equal "Post field", about_file_content 
  end

  def test_new_file_success
    post "/new", params={:filename => "kappa.txt"}
     
    assert_equal 302, last_response.status
    get last_response["Location"]

    assert_equal 200, last_response.status
    assert_includes last_response.body, "kappa.txt has been created."

    kappa_file_path = data_path + "/kappa.txt"
    kappa_file_content = File.read(kappa_file_path)

    assert_equal "", kappa_file_content
  end

  def test_new_file_empty_file_name_error
    post "/new"

    assert_equal 200, last_response.status
    assert_includes last_response.body, "A name is required."

    post "/new", params={:filename => ""}

    assert_equal 200, last_response.status
    assert_includes last_response.body, "A name is required."

    post "/new", params={:filename => "   "}

    assert_equal 200, last_response.status
    assert_includes last_response.body, "A name is required."
  end
end