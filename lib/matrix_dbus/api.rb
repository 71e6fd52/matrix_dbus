#
module MatrixAPI
  def get(url)
    uri = @host + '/_matrix/client/r0' + url
    puts 'GET URL:', uri if $VERBOSE
    JSON.parse RestClient.get(uri).body
  rescue RestClient::Exceptions::OpenTimeout
    retry
  rescue RestClient::BadGateway
    retry
  end

  def post(url, body)
    uri = @host + '/_matrix/client/r0' + url
    puts 'POST URL:', uri if $VERBOSE
    JSON.parse \
      RestClient.post(uri, body, content_type: :json, accept: :json).body
  rescue RestClient::Exceptions::OpenTimeout
    retry
  rescue RestClient::BadGateway
    retry
  end

  def put(url, body)
    uri = @host + '/_matrix/client/r0' + url
    puts 'PUT URL:', uri if $VERBOSE
    JSON.parse \
      RestClient.put(uri, body.to_json, content_type: :json, accept: :json).body
  rescue RestClient::Exceptions::OpenTimeout
    retry
  rescue RestClient::BadGateway
    retry
  end

  def upload_file(file, token)
    uri = @host + '/_matrix/media/r0/upload?access_token=' + token
    puts 'POST URL:', uri if $VERBOSE
    JSON.parse(RestClient.post(uri, file).body)['content_uri']
  rescue RestClient::Exceptions::OpenTimeout
    retry
  rescue RestClient::BadGateway
    retry
  end
end
