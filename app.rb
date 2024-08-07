require 'sinatra'
require 'digest/sha1'
require "sinatra/cors"

set :allow_origin, "*"
set :allow_methods, "GET,HEAD,POST"
set :allow_headers, "content-type,if-modified-since"
set :expose_headers, "location,link"

set :port, 8278

Dir.mkdir File.join(__dir__, "sites") unless Dir.exist? File.join(__dir__, "sites")

def gb_left_on_root_partition
  free = `df -h`.split("\n").select { |l| l.end_with? ' /' }.first.split[3]
  if free.end_with? 'G'
    return free.split('G').first.to_i
  end
  if free.end_with? 'T'
    return free.split('T').first.to_i * 1000
  end
  return 0
end

MIN_FREE_GB = 5

free = gb_left_on_root_partition
puts "free space on / partition: #{free}GB"
if free < MIN_FREE_GB
  puts "WARNING! system is ready only because there is not enough space on the drive"
end

get '/' do
  return 'hello'
end

def ok
    return JSON.generate({message: "OK"})
end

def error_msg(msg)
    return JSON.generate({error: msg})
end

def fail(msg)
  error(error_msg(msg))
end

def get_json
  content_type 'application/json'
  request.body.rewind
  payload = request.body.read
  if payload.size.zero?
    fail("payload is empty")
    return nil
  end
  begin
    json = JSON.parse payload
    return json.transform_keys(&:to_sym)
  rescue JSON::ParserError
    fail("invalid json")
    return nil
  end
end

post '/comments' do
  free = gb_left_on_root_partition
  if free < MIN_FREE_GB
    fail("disk is full")
    return
  end

  data = get_json
  return if data.nil?

  author = data[:author]
  message = data[:message]
  site = data[:site]

  if author.nil?
    return error_msg("author can not be empty")
  end
  if message.nil?
    return error_msg("message can not be empty")
  end
  if site.nil?
    return error_msg("site can not be empty")
  end
  if author.length > 32
    return error_msg("author can not be longer than 32 characters")
  end
  if message.length > 2048
    return error_msg("message can not be longer than 2048 characters")
  end

  site_sha = Digest::SHA1.hexdigest site
  site_dir = File.join(__dir__, "sites", site_sha)
  Dir.mkdir site_dir unless Dir.exist? site_dir

  num_comments = Dir["#{site_dir}/*.json"].length
  comment_id = num_comments + 1
  file_name = File.join(site_dir, "comment_#{comment_id.to_s.rjust(9, "0")}.json")
  content = JSON.generate({
    id: comment_id,
    author:,
    message:,
    date: Time.now.strftime("%Y-%m-%d %H:%M")
  })
  File.write file_name, content
  return content
end

get '/comments' do
  site = params[:site]
  if site.nil?
    return error_msg("site can not be empty")
  end
  site_sha = Digest::SHA1.hexdigest site
  site_dir = File.join(__dir__, "sites", site_sha)
  Dir.mkdir site_dir unless Dir.exist? site_dir

  comments = []

  comment_files = Dir["#{site_dir}/*.json"]

  count = params[:count] || 5
  count = count.to_i
  count = 5 if count > 5
  count = 1 if count < 1
  from = params[:from] || comment_files.length - count
  from = from.to_i
  from = 0 if from.negative?
  to = from + count

  range = comment_files[from...to]
  fail("invalid range") if range.nil?
  range.each do |comment|
    comments << JSON.parse(File.read comment)
  end


  return JSON.generate(total: comment_files.length, comments:)
end

