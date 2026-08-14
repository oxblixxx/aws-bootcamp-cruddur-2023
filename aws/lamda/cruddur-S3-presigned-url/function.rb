require 'aws-sdk-s3'
require 'json'
require 'jwt'

def handler(event:, context:)
  # Log the full event for debugging
  puts({step: 'received_event', event: event}.to_json)

  # --- CORS headers (reused everywhere) ---
  cors_headers = {
    "Access-Control-Allow-Headers" => "*, Authorization",
    "Access-Control-Allow-Origin"  => "https://front.mustaphaops.online",
    "Access-Control-Allow-Methods" => "OPTIONS,GET,POST"
  }

  # --- Handle preflight OPTIONS ---
  route_key = event['routeKey'] || event['httpMethod'] || ''
  if route_key == "OPTIONS /{proxy+}" || route_key == 'OPTIONS'
    puts({step: 'preflight', message: 'CORS preflight check'}.to_json)
    return {
      statusCode: 200,
      headers: cors_headers
    }
  end

  # --- Safely extract headers ---
  headers = event['headers'] || {}
  auth_header = headers['authorization'] || headers['Authorization']

  if auth_header.nil? || auth_header.empty?
    puts({step: 'error', message: 'Missing Authorization header'}.to_json)
    return {
      statusCode: 401,
      headers: cors_headers,
      body: { error: 'Unauthorized - missing Authorization header' }.to_json
    }
  end

  # Extract Bearer token
  token = auth_header.split(' ')[1]
  if token.nil? || token.empty?
    puts({step: 'error', message: 'Malformed Authorization header', auth_header: auth_header}.to_json)
    return {
      statusCode: 401,
      headers: cors_headers,
      body: { error: 'Unauthorized - malformed Authorization header' }.to_json
    }
  end

  puts({step: 'presignedurl', access_token: token}.to_json)

  # --- Safely parse body ---
  raw_body = event['body'] || '{}'
  begin
    body_hash = JSON.parse(raw_body)
  rescue JSON::ParserError => e
    puts({step: 'error', message: 'Invalid JSON body', error: e.message}.to_json)
    return {
      statusCode: 400,
      headers: cors_headers,
      body: { error: 'Invalid JSON body' }.to_json
    }
  end

  extension = body_hash['extension']
  if extension.nil? || extension.empty?
    puts({step: 'error', message: 'Missing extension in body'}.to_json)
    return {
      statusCode: 400,
      headers: cors_headers,
      body: { error: 'Missing extension in request body' }.to_json
    }
  end

  # --- Decode JWT ---
  begin
    decoded_token = JWT.decode(token, nil, false)
    cognito_user_uuid = decoded_token[0]['sub']
  rescue JWT::DecodeError => e
    puts({step: 'error', message: 'Invalid JWT', error: e.message}.to_json)
    return {
      statusCode: 401,
      headers: cors_headers,
      body: { error: 'Invalid token' }.to_json
    }
  end

  # --- Generate S3 presigned URL ---
  bucket_name = ENV['UPLOADS_BUCKET_NAME']
  if bucket_name.nil? || bucket_name.empty?
    puts({step: 'error', message: 'UPLOADS_BUCKET_NAME not set'}.to_json)
    return {
      statusCode: 500,
      headers: cors_headers,
      body: { error: 'Server configuration error' }.to_json
    }
  end

  object_key = "#{cognito_user_uuid}.#{extension}"
  puts({step: 'generate_url', object_key: object_key, bucket: bucket_name}.to_json)

  s3 = Aws::S3::Resource.new
  obj = s3.bucket(bucket_name).object(object_key)
  url = obj.presigned_url(:put, expires_in: 60 * 5)

  # --- Return success ---
  {
    statusCode: 200,
    headers: cors_headers,
    body: { url: url }.to_json
  }
end