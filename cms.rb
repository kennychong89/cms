require "sinatra"
require "sinatra/reloader"
require "sinatra/content_for"
require "tilt/erubis"
require "redcarpet"
FILE_PATH = File.join(File.dirname(__FILE__), 'files')

configure do
  enable :sessions
  set :sessions_secret, 'secret'
  set :erb, :escape_html => true
end

def data_path
  if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/data", __FILE__)
  else
    File.expand_path("../data", __FILE__)
  end
end

get "/" do
  @files = []
  Dir.glob("#{FILE_PATH}/*") { |filename| @files.push(File.basename(filename)) }
  erb :index
end

helpers do
  def convert_markdown(text)
    markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
    markdown.render(text)
  end
end

get "/:filename" do
  content_type "text/plain"
  
  file = "#{FILE_PATH}/#{params[:filename]}"

  if !File.exist?(file)
    session[:error] = "#{params[:filename]} does not exist."
    redirect "/"
  end

  if File.extname(file) == ".md"
    content_type "text/html"
    convert_markdown(File.read(file))
  else
    File.read(file)
  end
end

get "/:filename/edit" do
  @filename = params[:filename]
  file = "#{FILE_PATH}/#{@filename}"

  if !File.exist?(file)
    session[:error] = "#{@filename} does not exist."
    redirect "/"
  end

  @file_content = File.read(file)

  erb :edit
end

post "/:filename/edit" do
  @filename = params[:filename]
  file_content = params[:edittext]

  file = "#{FILE_PATH}/#{@filename}"

  if !File.exist?(file)
  	session[:error] = "Cannot update #{@filename}. #{@filename} does not exist."
  	redirect "/#{@filename}/edit"
  end
  
  File.open(file, 'w') { |file| file.write(file_content) }
  session[:success] = "#{@filename} has been updated."

  redirect "/"
end