$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__)) + "/lib")
require 'sinatra'
require 'json'
require 'beeline'
require 'beeline_timecard'
require 'date'
require 'parse_repository'

require 'consultant'

@@consultants = <<CONSULTANTS
              [
                {"first_name": "Kevin", "last_name": "Hickey", "roles": ["dev", "qa", "pm"], "beeline_guid":"00090026915", "rolloff":"2013-12-31", "hours_needed":0, "timecards": []},
                {"first_name": "David", "last_name": "Nelson", "roles": ["dev"], "beeline_guid":"00090026917", "rolloff":"2013-07-09", "hours_needed":0, "timecards": []},
                {"first_name": "Cecil", "last_name": "Dearborne", "roles": ["pm"], "beeline_guid":"00090027138", "hours_needed":0, "rolloff":"2013-07-05", "timecards": []},
                {"first_name": "Chisa", "last_name": "Nwabara", "roles": ["ba"], "beeline_guid":"00090028544", "hours_needed":0, "rolloff":"2013-09-30", "timecards": []}
              ]
CONSULTANTS


@@rates = {"consultant" => 157.50,
           "senior" => 168.75,
           "lead" => 180.00,
           "principal" => 202.50,
           "director" => 219.38
}

@@projects = {"Execution Services" => "00686202001",
              "AQP" => "00684057001",
              "FAR117" => "00686200001",
              "CODA AIT" => "00686191001",
}

def consultants_as_json
  consultant_hashes = []
  @@consultants.each do |consultant|
    consultant_hashes << consultant.to_hash
  end

  JSON.fast_generate consultant_hashes
end

@@config = {"mode" => "Development",
            "parse_application_id" => "WjDbcDcAfMJUPk01nfIZAP85skoEZGFGBKjuPsW3",
            "parse_api_key" => "Gr450bHB3lPuURvSaraBOVTlO4ovBiSiIXOlhUzd",
            "submit_to_beeline" => false
}

@@teams = <<TEAMS
              [
                {"id": "0", "name": "The Expendables", "pm_count": "1", "dev_count": "4", "ba_count": "1", "qa_count": "2", "pms": ["Hickey"]},
                {"id": "1", "name": "Transformers", "pm_count": "1", "dev_count": "2", "ba_count": "0", "qa_count": "0", "pms": [""]}
              ]
TEAMS

@@parse_repository = ParseRepository.new

@@consultants = @@parse_repository.get_all_consultants @@config["parse_application_id"], @@config["parse_api_key"]

get '/configuration' do
  JSON.fast_generate @@config
end

post '/configuration' do
  @@config = JSON.parse request.body.read

  if @@config["mode"] == "Production" then
    @@consultants = @@parse_repository.get_all_consultants @@config["parse_application_id"], @@config["parse_api_key"]
  end
  JSON.fast_generate @@config
end

post '/consultant' do
  new_consultant_as_hash = JSON.parse request.body.read
  puts new_consultant_as_hash
  new_consultant = Consultant.from_hash new_consultant_as_hash

  find_existing_timecards.each do |week_ending|
    new_consultant.add_timecard week_ending
  end

  @@consultants << new_consultant

  if (@@config["mode"] == "Production") then
    @@parse_repository.save_new_consultant new_consultant, @@config["parse_application_id"], @@config["parse_api_key"]
  end

  JSON.fast_generate new_consultant.to_hash
end

get '/consultant/beeline_guid/:beeline_guid' do
  JSON.fast_generate @@consultants.find {|consultant| consultant.beeline_guid == params[:beeline_guid]}.to_hash
end

get '/consultants/list' do
  content_type :json
  consultants_as_json
end

get '/consultant/detail' do
  erb :consultant_detail
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
  @@consultants.each do |consultant|
    consultant.add_timecard week_ending_date
    consultants_as_hash << consultant.to_hash
    if @@config["mode"] == "Production" then
      @@parse_repository.update_consultant consultant, @@config["parse_application_id"], @@config["parse_api_key"]
    end
  end

  consultants_as_json
end

def find_existing_timecards
  existing_timecards = Set.new

  @@consultants.each do |consultant|
    consultant.timecard_end_dates.each do |end_date|
      existing_timecards.add end_date
    end
  end
  existing_timecards
end

get '/timecard/list_existing' do
  content_type :json
  existing_timecards = find_existing_timecards()

  JSON.fast_generate existing_timecards.to_a
end

post '/timecard/enter_time' do
  week_ending_date = Date.strptime params["week_ending"], '%Y-%m-%d'
  beeline_guid = params["beeline_guid"]
  hours_to_enter = params["hours_to_enter"]
  consultant = @@consultants.find {|consultant| consultant.beeline_guid == beeline_guid}
  timecard = consultant.find_timecard week_ending_date

  if @@config["submit_to_beeline"] == true then
    beeline = Beeline.new()
    begin
      puts "impersonating #{beeline_guid}"
      beeline.impersonate beeline_guid
      beeline.enter_time @@projects[consultant.project], week_ending_date, hours_to_enter.to_i
      timecard.hours_submitted = hours_to_enter.to_i
    rescue Exception => e
      puts e.message
      timecard.submit_failed
    ensure
      beeline.stop_impersonating
    end
    beeline.close
  else
    sleep 3
    timecard.hours_submitted = hours_to_enter.to_i
  end

  if @@config["mode"] == "Production" then
    @@parse_repository.update_consultant consultant, @@config["parse_application_id"], @@config["parse_api_key"]
  end

  JSON.fast_generate timecard.to_hash
end

post '/timecard/time_submitted' do
  week_ending_date = Date.strptime params["week_ending"], '%Y-%m-%d'
  beeline_guid = params["beeline_guid"]
  hours_to_enter = params["hours_to_enter"]
  puts "Entering #{hours_to_enter} hours for #{beeline_guid} for week #{week_ending_date}"
  consultant = @@consultants.find {|consultant| consultant.beeline_guid == beeline_guid}
  puts "Found #{consultant.last_name}"

  consultant.time_submitted week_ending_date, hours_to_enter.to_i
  if @@config["mode"] == "Production" then
    @@parse_repository.update_consultant consultant, @@config["parse_application_id"], @@config["parse_api_key"]
  end

  consultants_as_json
end

get '/rates' do
  content_type :json
  JSON.fast_generate @@rates
end

get '/projects' do
  content_type :json
  JSON.fast_generate @@projects
end