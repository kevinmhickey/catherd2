require 'net/http'
require 'json'
require 'csv'

http = Net::HTTP.new("localhost", 4567)


csv_data = CSV.read("/Users/Thoughtworks/Downloads/SWA_Crew_Roster.csv")

keys = csv_data.shift
csv_data.each do |csv_line|
  puts csv_line
  new_consultant = {}
  keys.each_with_index do |key, index|
    new_consultant[key] = csv_line[index]
  end
  puts new_consultant
  new_consultant_as_json = JSON.fast_generate(new_consultant)
  puts new_consultant_as_json

  request = Net::HTTP::Post.new("/consultant")
  request.body = new_consultant_as_json
  http.request(request)
end

#
#timecard_data = CSV.read("/Users/Thoughtworks/Documents/timecards.csv")
#timecard_data.shift
#timecard_data.pop
#
#week_endings = timecard_data.shift
#week_endings.shift
#week_endings.pop
#
#week_endings.each do |week_ending|
#  request = Net::HTTP::Post.new("/timecard/add")
#  request.set_form_data({"week_ending_date" => week_ending})
#  http.request(request)
#end
#
#timecard_data.each do |timecard|
#  guid = timecard.shift
#  week_endings.each_with_index do |week_ending, index|
#    request = Net::HTTP::Post.new("/timecard/time_submitted")
#    hours_to_enter = timecard[index].nil? ? 0 : timecard[index]
#    request.set_form_data({"week_ending"=>week_ending, "beeline_guid"=>guid, "hours_to_enter"=>hours_to_enter})
#    http.request(request)
#  end
#end
#
