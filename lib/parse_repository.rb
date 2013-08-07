require 'net/http'
require 'json'
require 'consultant'

class ParseRepository
  def initialize
    @http = Net::HTTP.new("api.parse.com", 443)
    @http.use_ssl = true
    @http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  end

  def save_new_consultant consultant, parse_application_id, parse_api_key
    request = Net::HTTP::Post.new("/1/classes/Consultant")
    request.body = consultant.to_hash.to_json
    request["Content-Type"] = "application/json"
    request["X-Parse-REST-API-Key"] = parse_api_key
    request["X-Parse-Application-Id"] = parse_application_id

    result = @http.request(request)
    body = JSON.parse result.body
    if result.code.to_i <= 299 && result.code.to_i >= 200
      consultant.parse_object_id = body["objectId"]
    else
      raise body["error"]
    end
  end

  def update_consultant consultant, parse_application_id, parse_api_key
    request = Net::HTTP::Put.new("/1/classes/Consultant/#{consultant.parse_object_id}")
    request.body = consultant.to_hash.to_json
    request["Content-Type"] = "application/json"
    request["X-Parse-REST-API-Key"] = parse_api_key
    request["X-Parse-Application-Id"] = parse_application_id

    result = @http.request(request)
    body = JSON.parse result.body
    if result.code.to_i <= 499 && result.code.to_i >= 400
      raise body["error"]
    end
  end

  def get_all_consultants parse_application_id, parse_api_key
    request = Net::HTTP::Get.new("/1/classes/Consultant")
    request["Content-Type"] = "application/json"
    request["X-Parse-REST-API-Key"] = parse_api_key
    request["X-Parse-Application-Id"] = parse_application_id

    result = @http.request(request)
    body = JSON.parse result.body
    consultants = []

    if result.code.to_i <= 299 && result.code.to_i >= 200
      body["results"].each do |consultant_hash|
        consultants << Consultant.from_hash(consultant_hash)
      end
    else
      raise body["error"]
    end

    consultants
  end
end