require 'sinatra'
require 'dm-core'
require 'dm-timestamps'
require 'dm-validations'
require 'dm-migrations'
require 'fileutils'
require 'pry'

DataMapper.setup(:default, "sqlite://#{Dir.pwd}/mydatabase.db")

use Rack::Auth::Basic do |username, password|
  username == 'mario' && password == '9'
end

# model represents downloaded files
class StoredFile
  include DataMapper::Resource

  property :id, Serial
  property :filename, String
  property :created_at, DateTime
  property :tempfile, String

  default_scope(:default).update(order: [:created_at.desc])
end

DataMapper.finalize
DataMapper.auto_upgrade!

get '/' do
  @files = StoredFile.all
  erb :list
end

post '/submit_file' do
  redirect '/' if params['file'].nil?
  # '<script type="text/javascript">alert("U try to load free file")</script>'
  tempfile = params['file'][:tempfile]
  @file = StoredFile.new filename: params[:file][:filename],
                         created_at: Time.now
  @file.save!
  FileUtils.cp(tempfile.path, "./uploads/#{@file.id}.upload")
  redirect '/'
end

get '/download/:id' do
  @file = StoredFile.get(params[:id])
  redirect '/' if @file.nil?
  if File.file?("./uploads/#{@file.id}.upload")
    send_file "uploads/#{@file.id}.upload", filename: @file.filename,
                                            type: 'Application/octet-stream'
  end
  redirect '/'
end

get '/delete/:id' do
  tmp = StoredFile.get(params[:id])
  redirect '/' if tmp.nil?
  tmp.destroy
  FileUtils.rm("./uploads/#{params[:id]}.upload") if
    File.file?("./uploads/#{params[:id]}.upload")
  redirect '/'
end

get '/all/delete' do
  StoredFile.all.destroy
  FileUtils.rm Dir.glob('./uploads/*.upload')
  redirect '/'
end

not_found do
  status 404
  erb :not_found
end

error do
  "<script>alert('Error my friend')</script>"
end
