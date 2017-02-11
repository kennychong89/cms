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

helpers do
  def convert_markdown(text)
    markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
    markdown.render(text)
  end
end

def data_path
  if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/files", __FILE__)
  else
    File.expand_path("../files", __FILE__)
  end
end

get "/" do
  pattern = File.join(data_path, "*")
  @files = Dir.glob(pattern).map do |path| 
    File.basename(path)
  end
  erb :index, layout: :layout
end

get "/new" do
  erb :new, layout: :layout
end

get "/:filename" do
  content_type "text/plain"
  
  file_path = File.join(data_path, params[:filename])

  if !File.exist?(file_path)
    session[:error] = "#{params[:filename]} does not exist."
    redirect "/"
  end

  if File.extname(file_path) == ".md"
    content_type "text/html"
    erb convert_markdown(File.read(file_path))
  else
    File.read(file_path)
  end
end

get "/:filename/edit" do
  file_path = File.join(data_path, params[:filename])
  @filename = params[:filename]

  if !File.exist?(file_path)
    session[:error] = "#{@filename} does not exist."
    redirect "/"
  end

  @file_content = File.read(file_path)

  erb :edit, layout: :layout
end

post "/:filename/edit" do
  file_path = File.join(data_path, params[:filename])
  file_content = params[:edittext]

  if !File.exist?(file_path)
  	session[:error] = "Cannot update #{@filename}. #{@filename} does not exist."
  	redirect "/#{params[:filename]}/edit"
  end
  
  File.open(file_path, 'w') { |file| file.write(file_content) }
  session[:success] = "#{params[:filename]} has been updated."

  redirect "/"
end

post "/new" do
  if params[:filename].nil? or params[:filename].strip.empty?    
    session[:error] = "A name is required."
    erb :new, layout: :layout 
  else
    new_file = File.new(File.join(data_path, params[:filename].strip), 'w+')
    new_file.close()

    session[:success] = "#{params[:filename]} has been created."
 
    redirect "/"
  end
end