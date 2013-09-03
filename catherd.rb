$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__)) + "/lib")
require 'sinatra'
require 'json'
require 'beeline'
require 'beeline_timecard'
require 'date'
require 'parse_repository'
require 'dummy_repository'
require 'always_successful_timecard_submitter'
require 'herd'

require 'consultant'

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

@@repository = ParseRepository.new @@config["parse_application_id"], @@config["parse_api_key"]
@@herd = Herd.new @@repository

@@repository = DummyRepository.new @@herd.consultants
@@herd = Herd.new @@repository

@@consultants = @@repository.get_all_consultants.values
#@@consultants.each {|consultant| @@herd.add consultant}

get '/configuration' do
  JSON.fast_generate @@config
end

post '/configuration' do
  @@config = JSON.parse request.body.read

  if @@config["mode"] == "Production" then
    @@repository = ParseRepository.new @@config["parse_application_id"], @@config["parse_api_key"]
  else
    @@repository = DummyRepository.new @@herd.consultants
  end

  @@herd = Herd.new @@repository
  JSON.fast_generate @@config
end

#post '/consultant' do
#  new_consultant_as_hash = JSON.parse request.body.read
#  puts new_consultant_as_hash
#  new_consultant = Consultant.from_hash new_consultant_as_hash
#
#  find_existing_timecards.each do |week_ending|
#    new_consultant.add_timecard week_ending
#  end
#
#  @@consultants << new_consultant
#
#  if (@@config["mode"] == "Production") then
#    @@parse_repository.save_new_consultant new_consultant, @@config["parse_application_id"], @@config["parse_api_key"]
#  end
#
#  JSON.fast_generate new_consultant.to_hash
#end

get '/consultant/beeline_guid/:beeline_guid' do
  JSON.fast_generate @@herd.get(params[:beeline_guid]).to_hash
end

put '/consultant/beeline_guid/:beeline_guid' do
  consultant_hash = JSON.parse request.body.read
  consultant = Consultant.from_hash consultant_hash
  @@herd.update consultant

  JSON.fast_generate consultant.to_hash
end

get '/consultants/list' do
  content_type :json
  consultants_as_json
end

get '/consultant/detail' do
  erb :consultant_detail
end

post '/timecard/add/:week_ending' do
  week_ending_date = Date.strptime params[:week_ending], '%Y-%m-%d'
  @@herd.add_timecard week_ending_date

  JSON.fast_generate @@herd.find_existing_timecards.to_a
end

get '/timecard/list_existing' do
  content_type :json
  existing_timecards = @@herd.find_existing_timecards

  JSON.fast_generate existing_timecards.to_a
end

post '/timecard/submit' do
  body = request.body.read
  timecards = JSON.parse body
  week_ending_date = Date.strptime(timecards["week_ending_date"], '%Y-%m-%d')
  submitter = AlwaysSuccessfulTimecardSubmitter.new
  if @@config["submit_to_beeline"]
    submitter = Beeline.new
  end

  @@herd.enter_timecards submitter, week_ending_date, timecards["timecards"]
  submitter.close

  "SUCCESS"
end

get '/timecard/for_week_ending/:week_ending' do
  week_ending_date = Date.strptime params[:week_ending], '%Y-%m-%d'

  timecards = @@herd.get_timecards_for_entry week_ending_date
  result = {"submitting" => @@herd.submitting, "timecards" => timecards}

  JSON.fast_generate result
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
    #@@repository.update_consultant consultant, @@config["parse_application_id"], @@config["parse_api_key"]
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