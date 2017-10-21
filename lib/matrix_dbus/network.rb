module MatrixDBus
  # get, post
  #
  # Example:
  #   get = Network.gen :get, 'http://localhost:5700'
  #   json = get.call '/get_login_info'
  class Network
    # gen lambda
    #
    # type: Symbol or String, 'get', 'form' or 'json;
    # host: String: API address, like 'http://localhost:5700'
    def initialize(host, error) # => Hash<Symble, Lambda>
      @host = host.to_s
      @error = error
    end

    # get url
    #
    # uri: String
    # params (optional): Hash, url query
    def get(uri, params = nil) # => Hash
      uri = URI(@host + uri.to_s)
      uri.query = URI.encode_www_form params if params
      puts 'GET URL:', uri if $DEBUG
      error RestClient.get(uri.to_s)
    rescue RestClient::Exceptions::OpenTimeout
      retry
    rescue RestClient::BadGateway
      retry
    end

    # post json to url
    #
    # uri: String
    # body: Hash, post body
    def post(uri, body)
      uri = @host + uri.to_s
      puts 'POST URL:', uri if $DEBUG
      error RestClient.post(uri.to_s, body.to_json, content_type: :json)
    rescue RestClient::Exceptions::OpenTimeout
      retry
    rescue RestClient::BadGateway
      retry
    end

    # post raw to url
    #
    # uri: String
    # body: Anything
    def post_raw(uri, body)
      uri = @host + uri.to_s
      puts 'POST URL:', uri if $DEBUG
      error RestClient.post(uri.to_s, body)
    rescue RestClient::Exceptions::OpenTimeout
      retry
    rescue RestClient::BadGateway
      retry
    end

    # put to url
    #
    # uri: String
    # body: Hash, put body
    def put(uri, body)
      uri = @host + uri.to_s
      puts 'PUT URL:', uri.to_s if $DEBUG
      error RestClient.put(uri.to_s, body.to_json, content_type: :json)
    rescue RestClient::Exceptions::OpenTimeout
      retry
    rescue RestClient::BadGateway
      retry
    end

    # delete to url
    #
    # uri: String
    # params (optional): Hash, url query
    def delete(uri, params = nil) # => Hash
      uri = URI(@host + uri.to_s)
      puts 'DELETE URL:', uri if $DEBUG
      uri.query = String.encode_www_form params if params
      error RestClient.delete(uri.to_s)
    rescue RestClient::Exceptions::OpenTimeout
      retry
    rescue RestClient::BadGateway
      retry
    end

    private

    def error(res)
      @error.call res
    end
  end
end
