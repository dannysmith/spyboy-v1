require 'sinatra'
require './spyboy'
use Rack::Deflater #Enable GZip Compression - added 18 Jan 13
run SpyBoy