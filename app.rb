require 'rubygems'
require 'sinatra'
require 'mongoid'
require 'json'
# this is now using this https://github.com/treeder/rack-flash which is
# installed in the Gemfile as 'rack-flash3'
require 'rack-flash'
require 'digest/sha1'
require 'sinatra/reloader' if :development?

require_relative 'lib/helpers'
Dir[File.dirname(__FILE__) + '/models/*'].each {|file| require_relative file }

Mongoid.load!("config/mongoid.yml")

configure :test do
  puts 'Test configuration in use'
  puts 'env name = ' + Mongoid::Config::Environment.env_name.to_s
end
configure :development do
  puts 'Development configuration in use for cantoflash'
end
configure :production do
  puts 'Production configuration in use for cantoflash'
  disable :raise_errors
  disable :show_exceptions
end
set :mongo_logfile, File.join("log", "mongo-driver-#{settings.environment}.log")

use Rack::Session::Cookie, :secret => 'thisisadifferentsecret',
                           :key => 'content.session',
                           :domain => '.platform.local',
                           :path => '/'
use Rack::Flash

enable :sessions

configure :production, :test do
  not_found do
    erb :'404'
  end

  error do
    erb :'500'
  end
end

get '/' do
  erb :index
end

get '/collections/:uid' do
  logger.info('when calling collections/:uid, the session[:uid] = ' + session[:uid].to_s)
  if session[:uid].nil?
    token_value = request.cookies["token"]
    if token_value.nil?
      # TODO this needs to know where to redirect to...if that hasn't been
      # supplied in a callback then it should be a 404
      redirect 'http://app.platform.local'
    end
    @token = verify_token(token_value)
    if @token[:value] == false
      # TODO this needs to know where to redirect to...if that hasn't been
      # supplied in a callback then it should be a 404
      redirect 'http://app.platform.local'
    end
    # token is genuine so set session:
    session[:uid] = @token["uid"]
  end
  @current_user = User.where(:uid => session[:uid]).first
  # TODO this needs to ask the app what collections this user is allowed to
  # access
  @collection = Collection.where(:uid => params[:uid]).first
  erb :'collections/index'
end

# TODO not exactly RESTful
get '/session/destroy' do
  status 200
  {:message => "destroyed"}.to_json
end

