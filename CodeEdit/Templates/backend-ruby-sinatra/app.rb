require 'sinatra'
require 'json'

get '/' do
  content_type :json
  { project: '{{PROJECT_NAME}}', status: 'online' }.to_json
end
