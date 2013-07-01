require 'sinatra'

consultants = <<CONSULTANTS
              [
                {"first_name": "Kevin", "last_name": "Hickey", "role": "PM"}
              ]
CONSULTANTS

get '/consultant/new' do
  erb :new_consultant
end

get '/consultant/list' do
  content_type :json
  consultants
end

post '/consultant/save_all' do
  content_type :json
  puts params
  puts "Params size: #{params.size}"
  puts params[:consultants]
  consultants = params[:consultants]
end

