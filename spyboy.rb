#spyboy.rb
require "bundler/setup"
require "sinatra/base"

class SpyBoy < Sinatra::Base
  get "/" do
    "Hello Spyboy!"
  end
end