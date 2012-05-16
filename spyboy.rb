#spyboy.rb
require "bundler/setup"
require "sinatra/base"
require 'rubygems'
require 'data_mapper'

#Set up Datamapper connection to Postgres (on heroku) or Sqlite on localhost.
DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/development.db")

#Set up Data

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
  property :date_and_time,  DateTime,    :required => true
  property :description,    Text
  property :created_at,     DateTime
end

DataMapper.finalize

# DataMapper.auto_migrate! #DROPs table and recreates. Loose all data.
DataMapper.auto_upgrade! #Tries to change table. Not always cleanly.



class SpyBoy < Sinatra::Base
  
  configure do
    ENV['ADMIN_USERNAME'] = "bob"
    ENV['ADMIN_PASSWORD'] = "password"
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
      redirect "/dashboard"
    else
      status 404
      "Link could not be found"
    end
  end

  ## Shows -----------------

  post "/show" do
    "Create new Show. Post data must contain show data"
  end

  put "/show/:id" do
    "Edit a show. Post data must contain link data and show_id"
  end

  delete "/show/:id" do
    "Remove link. Post data must contain show_id"
  end

  get "/show/:id/edit" do
    "Show Edit form for show"
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
       redirect "/dashboard"
     else
       status 404
       "Email Address could not be found"
     end
  end

  get "/email" do
    @emails = ""
    Email.all.each do |email|
      @emails += email.address + ", "
    end
    return @emails
  end
end

get "/:show_slug" do
  "Show Page for show."
end