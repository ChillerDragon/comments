require 'sinatra'

get '/' do
  return 'hello'
end

def get_json
  content_type 'application/json'
  request.body.rewind
  payload = request.body.read
  if payload.size.zero?
    return nil
  end
  return JSON.parse payload
end

post '/comments' do
  data = get_json
  if data.nil?
    return JSON.generate({error: "payload empty"})
  end
  return "uwuw"
end
