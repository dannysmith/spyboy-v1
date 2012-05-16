#spyboy.rb
require "bundler/setup"
require "sinatra/base"
require 'rubygems'
require 'data_mapper'
require 'carrierwave'
require 'carrierwave/datamapper'
require 'sinatra/flash'

####################### CARRIERWAVE SETUP ##########################

CarrierWave.configure do |config|  
  config.root = "#{Dir.pwd}/public"
# Set up Carrierwave - Production
#   config.fog_credentials = {
#     :provider               => 'AWS',       # required
#     :aws_access_key_id      => 'XXX',       # required
#     :aws_secret_access_key  => 'yyy',       # required
#     :region                 => 'eu-west-1'  # optional, defaults to 'us-east-1'
#   }
#   config.fog_directory  = 'name_of_directory'                     # required
#   config.fog_host       = 'https://assets.example.com'            # optional, defaults to nil
#   config.fog_public     = false                                   # optional, defaults to true
#   config.fog_attributes = {'Cache-Control'=>'max-age=315576000'}  # optional, defaults to {}
end

#Set up CarrierWave image uploader
class ShowImageUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick
  def extension_white_list
    %w(jpg jpeg gif png)
  end
  # storage :fog
  def store_dir
    "#{Dir.pwd}/public/img/uploads"
  end
  def cache_dir
    "#{Dir.pwd}/public/img/uploads/tmp"
  end
  process :resize_to_limit => [720,720]
  version :thumb do
    process :resize_to_fill => [60,60]
  end
end

####################### DATABASE SETUP ##########################

#Set up Datamapper connection to Postgres (on heroku) or Sqlite on localhost.
DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/development.db")

class Link
  include DataMapper::Resource

  property :id,           Serial
  property :title,        String,    :required => true
  property :url,          String,    :required => true
  property :description,  String,    :required => true
  property :created_at,   DateTime
end

class Email
  include DataMapper::Resource

  property :id,         Serial
  property :address,    String,    :required => true
  property :created_at, DateTime
end

class Show
  include DataMapper::Resource

  property :id,             Serial
  property :title,          String,    :required => true
  property :venue,          String,    :required => true
  property :venue_url,      String
  property :slug,           String
  property :date_and_time,  DateTime,  :required => true
  property :description,    Text
  property :created_at,     DateTime
  
  mount_uploader :image1, ShowImageUploader
  mount_uploader :image2, ShowImageUploader
  
  def date_to_s
    self.date_and_time.strftime('%a %d %b %Y')
  end
  
  def time_to_s
    self.date_and_time.strftime('%l:%M %p')
  end
end

DataMapper.finalize
# DataMapper.auto_migrate! #DROPs table and recreates. Loose all data.
DataMapper.auto_upgrade! #Tries to change table. Not always cleanly.

#################### SETTINGS AND ROUTES ###################

class SpyBoy < Sinatra::Base
  
  configure do
    ENV['ADMIN_USERNAME'] = "bob"
    ENV['ADMIN_PASSWORD'] = "password"
    
    enable :sessions
  end
  
  
  ## Main -----------------

  get "/" do
    @links = Link.all
    erb :index
  end

  get "/admin" do
    erb :signin
  end

  post "/admin" do
    # TODO: Set up a Session token and proper protection.
    if (params[:username] == ENV['ADMIN_USERNAME']) && (params[:password] == ENV['ADMIN_PASSWORD'])
      erb :dashboard
    else
      # TODO: Add Flash message for bad login
      erb :signin
    end
  end

  get "/dashboard" do
    @links = Link.all
    @emails = Email.all
    @shows = Show.all
    erb :dashboard
  end







  ## Links -----------------

  post "/link" do
    puts "Creating new Link"
    params[:created_at] = Time.now
    params.delete("submit")
    
    @link = Link.new(params)
    if @link.save
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
      str = @show.title
      str = str.gsub(/[^a-zA-Z0-9 ]/,"")
      str = str.gsub(/[ ]+/," ")
      str = str.gsub(/ /,"-")
      str += "-" + @show.id.to_s
      str = str.downcase
      @show.slug = str
      @show.save
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
      "Link could not be found"
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
      # TODO: Add Flash Message & Proper Error Handling/Validation.
      redirect "/"
    else
      status 500
      "An Error Occured. The Email couldn't be added couldn't save."
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
    @show = Show.first(slug: params[:show_slug])
    erb :view_show
  end
end
