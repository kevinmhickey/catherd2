$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__)) + "/lib")
require 'sinatra'
require 'json'
require 'beeline'
require 'beeline_timecard'
require 'date'

consultants = <<CONSULTANTS
              [
                {"first_name": "Kevin", "last_name": "Hickey", "roles": ["dev", "qa", "pm"], "beeline_guid":"00090026915", "rolloff":"2013-12-31", "hours_needed":0, "timecards": [{"week_ending":"2013-07-07", "hours_needed":40, "hours_submitted":0}]},
                {"first_name": "David", "last_name": "Nelson", "roles": ["dev"], "beeline_guid":"00090026917", "rolloff":"2013-07-09", "hours_needed":0, "timecards": [{"week_ending":"2013-07-07", "hours_needed":40, "hours_submitted":10}]},
                {"first_name": "Cecil", "last_name": "Dearborne", "roles": ["pm"], "beeline_guid":"00090027138", "hours_needed":0, "rolloff":"2013-07-05", "timecards": [{"week_ending":"2013-07-07", "hours_needed":40, "hours_submitted":0}]},
                {"first_name": "Chisa", "last_name": "Nwabara", "roles": ["ba"], "beeline_guid":"00090028544", "hours_needed":0, "rolloff":"2013-09-30", "timecards": [{"week_ending":"2013-07-07", "hours_needed":40, "hours_submitted":0}]}
              ]
CONSULTANTS

teams = <<TEAMS
              [
                {"id": "0", "name": "The Expendables", "pm_count": "1", "dev_count": "4", "ba_count": "1", "qa_count": "2", "pms": ["Hickey"]},
                {"id": "1", "name": "Transformers", "pm_count": "1", "dev_count": "2", "ba_count": "0", "qa_count": "0", "pms": [""]}
              ]
TEAMS

get '/consultants' do
  erb :new_consultant
end

get '/consultants/list' do
  content_type :json
  consultants
end

post '/consultants/save_all' do
  content_type :json
  puts params
  puts "Params size: #{params.size}"
  puts params[:consultants]
  consultants = params[:consultants]
end

get '/teams' do
  erb :edit_teams
end

get '/teams/list' do
  content_type :json
  teams
end

post '/teams/save_all' do
  content_type :json
  puts params[:teams]
  teams = params[:teams]
end

get '/assign' do
  erb :assign_teams
end

post '/timecard/enter_time' do
  content_type :json
  enter_time = JSON.parse request.body.read
  puts enter_time

  beeline = Beeline.new()
  week_ending = Date.strptime enter_time["week_ending"], '%Y-%m-%d'
  timecards = enter_time["timecards"]
  timecards.each do |timecard|
    hours = timecard["hours"].to_i
    guid = timecard["guid"]

    begin
      puts "impersonating #{guid}"
      beeline.impersonate guid
      beeline.enter_time week_ending, hours
      timecard["hours_submitted"] = hours
    rescue Exception => e
      timecard["hours_submitted"] = 0
      puts e.message
    ensure
      beeline.stop_impersonating
    end
  end

  beeline.close
  enter_time.to_json
end

get '/timecard' do
  erb :enter_time
end