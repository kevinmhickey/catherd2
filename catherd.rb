$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__)) + "/lib")
require 'sinatra'
require 'json'
require 'beeline'
require 'beeline_timecard'
require 'date'

require 'consultant'

@@consultants = <<CONSULTANTS
              [
                {"first_name": "Kevin", "last_name": "Hickey", "roles": ["dev", "qa", "pm"], "beeline_guid":"00090026915", "rolloff":"2013-12-31", "hours_needed":0, "timecards": []},
                {"first_name": "David", "last_name": "Nelson", "roles": ["dev"], "beeline_guid":"00090026917", "rolloff":"2013-07-09", "hours_needed":0, "timecards": []},
                {"first_name": "Cecil", "last_name": "Dearborne", "roles": ["pm"], "beeline_guid":"00090027138", "hours_needed":0, "rolloff":"2013-07-05", "timecards": []},
                {"first_name": "Chisa", "last_name": "Nwabara", "roles": ["ba"], "beeline_guid":"00090028544", "hours_needed":0, "rolloff":"2013-09-30", "timecards": []}
              ]
CONSULTANTS

@@cons = [Consultant.new("Hickey", "Kevin", "00090026915", Date.new(2012, 8, 1), Date.new(2014, 12, 31)),
          Consultant.new("Nelson", "David", "00090026917", Date.new(2012, 8, 1), Date.new(2013, 7, 9)),
          Consultant.new("Dearborne", "Cecil", "00090027138", Date.new(2012, 11, 15), Date.new(2013, 7, 5)),
          Consultant.new("Nwabara", "Chisa", "00090028544", Date.new(2013, 1, 22), Date.new(2013, 9, 30))]

def consultants_as_json
  consultant_hashes = []
  @@cons.each do |consultant|
    consultant_hashes << consultant.to_hash
  end

  JSON.fast_generate consultant_hashes
end

@@teams = <<TEAMS
              [
                {"id": "0", "name": "The Expendables", "pm_count": "1", "dev_count": "4", "ba_count": "1", "qa_count": "2", "pms": ["Hickey"]},
                {"id": "1", "name": "Transformers", "pm_count": "1", "dev_count": "2", "ba_count": "0", "qa_count": "0", "pms": [""]}
              ]
TEAMS

get '/consultant' do
  erb :consultant
end

post '/consultant' do
  new_consultant_as_hash = JSON.parse request.body.read
  puts new_consultant_as_hash
  new_consultant = Consultant.from_hash new_consultant_as_hash
  @@cons << new_consultant

  JSON.fast_generate new_consultant.to_hash
end

get '/consultants/list' do
  content_type :json
  consultants_as_json
end

#get '/teams' do
#  erb :edit_teams
#end
#
#get '/teams/list' do
#  content_type :json
#  @@teams
#end
#
#post '/teams/save_all' do
#  content_type :json
#  puts params[:teams]
#  @@teams = params[:teams]
#end
#
#get '/assign' do
#  erb :assign_teams
#end
#
post '/timecard/add' do
  week_ending_date = Date.strptime request[:week_ending_date], '%Y-%m-%d'
  consultants_as_hash = []
  @@cons.each do |consultant|
    consultant.add_timecard week_ending_date
    consultants_as_hash << consultant.to_hash
  end

  consultants_as_json
end

get '/timecard/list_existing' do
  content_type :json
  existing_timecards = Set.new

  @@cons.each do |consultant|
    consultant.timecard_end_dates.each do |end_date|
      existing_timecards.add end_date
    end
  end

  JSON.fast_generate existing_timecards.to_a
end

post '/timecard/enter_time' do
  week_ending_date = Date.strptime params["week_ending"], '%Y-%m-%d'
  beeline_guid = params["beeline_guid"]
  hours_to_enter = params["hours_to_enter"]
  consultant = @@cons.find {|consultant| consultant.beeline_guid == beeline_guid}

  beeline = Beeline.new()
  begin
    puts "impersonating #{beeline_guid}"
    beeline.impersonate beeline_guid
    beeline.enter_time week_ending_date, hours_to_enter.to_i
    consultant.time_submitted week_ending_date, hours_to_enter.to_i
  rescue Exception => e
    puts e.message
    consultant.time_submitted week_ending_date, 0
  ensure
    beeline.stop_impersonating
  end

  beeline.close
  consultants_as_json
end

get '/timecard' do
  erb :timecard
end