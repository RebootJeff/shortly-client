require 'sinatra'
require "sinatra/reloader" if development?
require 'active_record'
require 'uri'
require 'nokogiri'

###########################################################
# Configuration
###########################################################

set :public_folder, File.dirname(__FILE__) + '/public'

configure :development, :production do
    ActiveRecord::Base.establish_connection(
       :adapter => 'sqlite3',
       :database =>  'db/dev.sqlite3.db'
     )
end

# Handle potential connection pool timeout issues
after do
    ActiveRecord::Base.connection.close
end

# turn off root element rendering in JSON
ActiveRecord::Base.include_root_in_json = false

###########################################################
# Models
###########################################################
# Models to Access the database through ActiveRecord.
# Define associations here if need be
# http://guides.rubyonrails.org/association_basics.html

class Link < ActiveRecord::Base
    attr_accessible :url, :code, :visits, :title

    belongs_to :user

    has_many :clicks

    validates :url, presence: true

    before_save do |record|
        record.code = Digest::SHA1.hexdigest(url)[0,5]
    end
end

class Click < ActiveRecord::Base
    belongs_to :link, counter_cache: :visits, :touch => true
end

class User < ActiveRecord::Base
    attr_accessible :username, :password

    validates :username, uniqueness: true

    has_many :links
end


###########################################################
# Routes
###########################################################
enable :sessions
require 'sinatra/security'
include Sinatra::Security

get '/' do
    erb :login
end

get '/logout' do
    session.clear
    redirect '/'
end

post '/' do
    if params[:register].nil?  ## login
        user = User.find_by_username(params[:username])
        if user
            crypted = Password::Hashing.encrypt(params[:password])  ## need new password hash function.
            if Password::Hashing.check(params[:password], crypted)
                session[:username] = user.username
                redirect '/home'
            else
                [404, "Wrong Password."]
            end
        else
            redirect '/'
        end
    else   ## register
        crypted = Password::Hashing.encrypt(params[:password])
        user = User.new(username: params[:username], password: crypted)
        session[:username] = user.username
        if user.save
            redirect '/home'
        else
            redirect '/'
        end
    end
end

get '/home' do
    if session[:username].nil?
        redirect '/'
    else
        erb :index
    end
end

# get '/create' do
#     if session[:username].nil?
#         redirect '/'
#     else
#         erb :index
#     end
# end

get '/links' do
    if session[:username].nil?
        redirect '/'
    else
        user = User.find_by_username(session[:username])
        links = Link.all
        links.map { |link|
            link.as_json.merge(base_url: request.base_url)
        }.to_json
    end
end

post '/links' do
    if session[:username].nil?
        redirect '/'
    else
        data = JSON.parse request.body.read
        puts "OY! DATA! #{data}"
        uri = URI(data['url'])
        raise Sinatra::NotFound unless uri.absolute?
        user = User.find_by_username(session[:username])
        link = user.links.find_by_url(uri.to_s) ||
               user.links.create( url: uri.to_s, title: get_url_title(uri), user_id: user.id)
        # img = Nokogiri::HTML(open("#{uri.to_s}")).xpath('//img').first.attribute('src').to_s
        # link.update_attribute(:image, img)
        link.touch
        link.as_json.merge(base_url: request.base_url).to_json
    end
end

get '/:url' do
    link = Link.find_by_code params[:url]
    raise Sinatra::NotFound if link.nil?
    link.clicks.create!
    redirect link.url
end

get '/:code/stats' do
    if session[:username].nil?
        redirect '/'
    else
        @link = Link.find_by_code params[:code]
        erb :stats
    end
end

###########################################################
# Utility
###########################################################

# def read_url_head url
#     head = ""
#     url.open do |u|
#         begin
#             line = u.gets
#             next  if line.nil?
#             head += line
#             break if line =~ /<\/head>/
#         end until u.eof?
#     end
#     head + "</html>"
# end

def get_url_title url
    # Nokogiri::HTML.parse( read_url_head url ).title
    # result = read_url_head(url).match(/<title>(.*)<\/title>/)
    # result.nil? ? "" : result[1]
    url.to_s.slice(8)
end
