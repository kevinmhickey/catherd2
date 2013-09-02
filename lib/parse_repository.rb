require 'net/http'
require 'json'
require 'consultant'

class ParseRepository
  def initialize application_id, api_key
    @application_id = application_id
    @api_key = api_key
    @http = Net::HTTP.new("api.parse.com", 443)
    @http.use_ssl = true
    @http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  end

  def save_new_consultant consultant
    request = Net::HTTP::Post.new("/1/classes/Consultant")
    request.body = consultant.to_hash.to_json
    request["Content-Type"] = "application/json"
    request["X-Parse-REST-API-Key"] = @api_key
    request["X-Parse-Application-Id"] = @application_id

    result = @http.request(request)
    body = JSON.parse result.body
    if result.code.to_i <= 299 && result.code.to_i >= 200
      consultant.parse_object_id = body["objectId"]
    else
      raise body["error"]
    end
  end

  def update_consultant consultant
    request = Net::HTTP::Put.new("/1/classes/Consultant/#{consultant.parse_object_id}")
    request.body = consultant.to_hash.to_json
    request["Content-Type"] = "application/json"
    request["X-Parse-REST-API-Key"] = @api_key
    request["X-Parse-Application-Id"] = @application_id

    result = @http.request(request)
    body = JSON.parse result.body
    if result.code.to_i <= 499 && result.code.to_i >= 400
      raise body["error"]
    end
  end

  def get_all_consultants
    request = Net::HTTP::Get.new("/1/classes/Consultant")
    request["Content-Type"] = "application/json"
    request["X-Parse-REST-API-Key"] = @api_key
    request["X-Parse-Application-Id"] = @application_id

    result = @http.request(request)
    body = JSON.parse result.body
    consultants = {}

    if result.code.to_i <= 299 && result.code.to_i >= 200
      body["results"].each do |consultant_hash|
        consultant = Consultant.from_hash(consultant_hash)
        consultants[consultant.beeline_guid] = consultant
      end
    else
      raise body["error"]
    end

    consultants
  end
end