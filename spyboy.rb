#spyboy.rb
require "bundler/setup"
require 'sinatra/base'
require 'sinatra/flash'
require 'rubygems'
require 'data_mapper'
require 'carrierwave'
require 'fog'
require 'carrierwave/datamapper'
require 'tzinfo'

configure(:development) do
  require './development-envs'
end


####################### CARRIERWAVE SETUP ##########################

CarrierWave.configure do |config|
  #Set up Carrierwave - Production
  config.fog_credentials = {
    :provider               => 'AWS',       # required
    :aws_access_key_id      => ENV['AWS_ACCESS_KEY_ID'],       # required
    :aws_secret_access_key  => ENV['AWS_SECRET_ACCESS_KEY'],       # required
    :region                 => 'eu-west-1'  # optional, defaults to 'us-east-1'
  }
  config.fog_directory  = 'spyboy'                                # required
  config.fog_attributes = {'Cache-Control'=>'max-age=315576000'}  # optional, cache set to 10 years.
end

#Set up CarrierWave image uploader
class ShowImageUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick
  
  storage :fog
  
  def extension_white_list
    %w(jpg jpeg gif png)
  end
  # storage :fog
  def store_dir
    "#{Dir.pwd}/public/img/uploads"
  end
  def cache_dir
    "#{Dir.pwd}/tmp/uploads"
  end
  def filename
       @name ||= "#{secure_token}.#{file.extension}" if original_filename.present?
  end

  process :resize_to_limit => [720,720]
  version :thumb do
    process :resize_to_fill => [60,60]
  end
  version :mini do
    process :resize_to_fill => [32,32]
  end
  version :medium do
    process :resize_to_fit => [200,600]
  end
  
  protected
  def secure_token
    var = :"@#{mounted_as}_secure_token"
    model.instance_variable_get(var) or model.instance_variable_set(var, SecureRandom.uuid)
  end
end

####################### DATABASE SETUP ##########################

#Set up Datamapper connection to Postgres (on heroku) or Sqlite on localhost.
DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/development.db")

class Link
  include DataMapper::Resource

  property :id,           Serial
  property :title,        String,    :required => true
  property :url,          String,    :required => true, :length => 100
  property :description,  Text,      :required => true
  property :created_at,   DateTime
end

class Email
  include DataMapper::Resource

  property :id,         Serial
  property :address,    String,      :required => true
  property :created_at, DateTime
end

class Show
  include DataMapper::Resource

  property :id,             Serial
  property :title,          String,    :required => true, :length => 150
  property :venue,          String,    :required => true
  property :venue_url,      String,                       :length => 150
  property :slug,           String,                       :length => 160
  property :date_and_time,  DateTime,  :required => true
  property :description,    Text
  property :created_at,     DateTime
  
  mount_uploader :image1, ShowImageUploader
  mount_uploader :image2, ShowImageUploader
  
  def date_to_s
    self.date_and_time.strftime('%a %d %b %Y')
  end
  
  def short_date_to_s
    self.date_and_time.strftime('%d %b %y')
  end
  
  def time_to_s
    self.date_and_time.strftime('%l:%M %p')
  end
  
  def self.future
    # Gets all shows that haven't started yet. +28800 is a rudimentary conversion from heroku time (UTC-7).
    self.all(:date_and_time.gt => (Time.now + 28800), :order => [ :date_and_time.asc ])
  end
end

DataMapper.finalize
# DataMapper.auto_migrate! #DROPs table and recreates. Loose all data.
DataMapper.auto_upgrade! #Tries to change table. Not always cleanly.

#################### SETTINGS AND ROUTES ###################

class SpyBoy < Sinatra::Base
  
  configure(:development) do
    enable :sessions
  end
  
  set :session_secret, ENV['SESSION_SECRET'] ||= 'this_is_my_super_secret_foo'
  use Rack::Session::Cookie
  register Sinatra::Flash
  
  ## Main -----------------


  # Silly home-baked authentication
  # Whitelist of pages that will have the authentication code run.
  ["/dashboard", "/signout", "/link", "/link/*", "/show", "/show/*", "/email/*", "/email.*"].each do |path|
    before path do
      unless session[:admin_user]
        flash[:info] = "Your session has timed out. Please log in again."
        redirect "/admin" 
      end
    end
  end
  
    
    
    
    
    
  get "/d" do
    puts "Debugging..."
    puts ENV['AWS_SECRET_ACCESS_KEY']
    puts ENV['ADMIN_USERNAME']
    erb "<h1>Debug</h1>"
  end
  
  
  get "/" do
    @links = Link.all
    @shows = Show.future
    erb :index
  end

  get "/admin" do
    if session[:admin_user]
      redirect "dashboard"
    else
      erb :signin
    end
  end

  post "/admin" do
    if (params[:username] == ENV['ADMIN_USERNAME']) && (params[:password] == ENV['ADMIN_PASSWORD'])
      session[:admin_user] = true
      redirect "/dashboard"
    else
      flash[:error] = "Wrong Login! Please try again."
      redirect "/admin"
    end
  end

  get "/dashboard" do
    @links = Link.all
    @emails = Email.all(:order => [ :address.asc ])
    @shows = Show.all(:order => [ :date_and_time.desc ])
    erb :dashboard
  end

  get "/signout" do
    session.clear
    redirect "/"
  end






  ## Links -----------------

  post "/link" do
    puts "Creating new Link"
    params[:created_at] = Time.now
    params.delete("submit")
    
    @link = Link.new(params)
    if @link.save
      flash[:info] = "Done!"
      redirect "/dashboard"
    else
      status 500
      "An Error Occured. The Link couldn't save."
    end
  end

  get "/link/:id/edit" do
    @link = Link.get(params[:id])
    erb :_edit_link, layout: :modal_layout
  end
  
  post "/link/:id" do
    @link = Link.get(params[:id])
    puts "Updating Link ID #{@link.id} - #{params.to_s}"
    
    ["_method", "submit", "splat", "captures"].each { |k| params.delete(k) }
        
    if @link.update(params)
      flash[:info] = "Done!"
      erb :_done, layout: :modal_layout
    else
      status 500
      "An Error Occured. The Link couldn't be updated."
    end
  end

  delete "/link/:id" do
    @link = Link.get(params[:id])
    if @link.destroy
      status 200
    else
      status 404
      "Link could not be found"
    end
  end








  ## Shows -----------------

  post "/show" do
    params[:created_at] = Time.now
    params.delete("submit")
    
    @show = Show.new(params)
    
    if @show.save
      #Must save first in order to aquire an id. Then save again after building slug.
      str = @show.title
      str = str.gsub(/[^a-zA-Z0-9 ]/,"")
      str = str.gsub(/[ ]+/," ")
      str = str.gsub(/ /,"-")
      str += "-" + @show.id.to_s
      str = str.downcase
      @show.slug = str
      @show.save
      flash[:info] = "Added show: \"#{params[:title]}\"."
      erb :_done, layout: :modal_layout
    else
      status 500
      "An Error Occured. The Show couldn't save."
    end
  end

  post "/show/:id" do
    @show = Show.get(params[:id])
    str = params[:title]
    str = str.gsub(/[^a-zA-Z0-9 ]/,"")
    str = str.gsub(/[ ]+/," ")
    str = str.gsub(/ /,"-")
    str += "-" + params[:id].to_s
    str = str.downcase
    params[:slug] = str
    puts "Updating Show ID #{@show.id} - #{params.to_s}"
    
    ["_method", "submit", "splat", "captures"].each { |k| params.delete(k) }
        
    if @show.update(params)
      flash[:info] = "\"#{params[:title]}\" has been updated."
      erb :_done, layout: :modal_layout
    else
      status 500
      "An Error Occured. The Show couldn't be updated."
    end
  end

  delete "/show/:id" do
    @show = Show.get(params[:id])
    if @show.destroy
      status 200
    else
      status 404
      "Show could not be found"
    end
  end
  
  get "/show/add" do
    erb :_add_show, layout: :modal_layout
  end
  
  get "/show/:id/edit" do
    @show = Show.get(params[:id])
    erb :_edit_show, layout: :modal_layout
  end







  ## Email Addresses -----------------

  post "/email" do
    puts "Adding #{params[:address]} to database"
    params[:created_at] = Time.now
    params.delete("submit")
    
    @email = Email.new(params)
    if @email.save
      flash[:info] = "Your email's been added to the mailing list."
      redirect "/"
    else
      status 500
      flash[:error] = "Sorry! An error's occured. Please try signing up again."
      redirect "/"
    end
  end

  delete "/email/:id" do
    @email = Email.get(params[:id])
     if @email.destroy
       status 200
     else
       status 404
       "Email Address could not be found"
     end
  end

  get "/email.csv" do
    content_type 'text/plain', charset: 'utf-8'
    @emails = ""
    Email.all.each do |email|
      @emails += email.address + ", "
    end
    return @emails
  end
  
  get "/:show_slug" do
    @links = Link.all
    @show = Show.first(slug: params[:show_slug])
    erb :view_show
  end
end
