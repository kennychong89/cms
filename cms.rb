require "sinatra"
require "sinatra/reloader"
require "sinatra/content_for"
require "tilt/erubis"

FILE_PATH = "files"

get "/" do
  @files = []
  Dir.glob("#{FILE_PATH}/*") { |filename| @files.push(File.basename(filename)) }
  erb :index
end

get "/:filename" do
  file_text = File.readlines("#{FILE_PATH}/#{params[:filename]}")
end