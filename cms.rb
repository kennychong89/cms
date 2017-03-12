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

  def valid_credentials?(username, password)
    username == "admin" and password == "success"
  end

  def signed_in?
    !session[:user].nil?
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
  if !signed_in?
    session[:error] = "You must be signed in to do that"
    redirect "/"   
  end

  erb :new, layout: :layout
end

get "/users/signin" do
  if !session[:user].nil?
    session[:error] = "You are already logged in"
    redirect "/"
  else
    erb :signin, layout: :layout
  end
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
  if !signed_in?
    session[:error] = "You must be signed in to do that"
    redirect "/" 
  end

  file_path = File.join(data_path, params[:filename])
  @filename = params[:filename]

  if !File.exist?(file_path)
    session[:error] = "#{@filename} does not exist."
    redirect "/"
  end

  @file_content = File.read(file_path)

  erb :edit, layout: :layout
end

post "/users/signin" do
  username = params[:username]
  password = params[:password]
  
  if valid_credentials?(username, password) 
    session[:success] = "Welcome!"
    session[:user] = {:username => username, :password => password}
    redirect "/"
  else
    session[:error] = "Invalid Credentials"
    erb :signin, layout: :layout 
  end
end

post "/users/signout" do
  session.delete(:user)
  session[:success] = "You have been signed out."
  redirect "/"
end

post "/:filename/edit" do
  if !signed_in?
    session[:error] = "You must be signed in to do that"
    redirect "/"   
  end

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
  if !signed_in?
    session[:error] = "You must be signed in to do that"
    redirect "/"   
  end

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

post "/:filename/delete" do
  if !signed_in?
    session[:error] = "You must be signed in to do that"
    redirect "/"   
  end

  if !File.exist?(File.join(data_path, params[:filename]))
    session[:error] = "Cannot delete the file. File doesn't exists."
    erb :index, layout: :layout
  else
    File.delete(File.join(data_path, params[:filename]))
    session[:success] = "#{params[:filename]} was deleted."
    redirect "/"
  end
end