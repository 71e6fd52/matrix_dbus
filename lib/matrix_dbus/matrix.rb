module MatrixDBus
  #
  class Matrix
    attr_reader :json, :access_token, :network

    def initialize(username: '', password: '', host: 'https://matrix.org:8448')
      @username = username
      @password = password
      @run = true
      @event_method = []
      @config = File.join(ENV['HOME'], '.config', 'matrix-qq')
      @network = Network.new(host + '/_matrix/client/r0', method(:error))
      load_token
      load_batch
    end

    def bind(func)
      @event_method << func
    end

    def save_token
      unless File.directory? @config
        File.delete @config if File.exist? @config
        Dir.mkdir @config
      end
      File.open File.join(@config, 'token'), 'w', 0o600 do |f|
        f.puts @access_token
      end
    end

    def load_token
      login unless File.exist? File.join @config, 'token'
      login unless File.size? File.join @config, 'token'
      File.open File.join(@config, 'token'), 'r', 0o600 do |f|
        @access_token = f.gets.chomp
      end
    end

    def save_batch
      puts @next_batch if $DEBUG
      File.open File.join(@config, 'batch'), 'w' do |f|
        f.puts @next_batch
      end
    end

    def load_batch
      sync unless File.exist? File.join(@config, 'batch')
      File.open File.join(@config, 'batch') do |f|
        @next_batch = f.gets.chomp
      end
    end

    def check_login
      json = @network.get '/login'
      raise "can't login" unless json['flows'].find do |f|
        f['type'] == 'm.login.password'
      end
    end

    def login
      check_login
      raise 'Unknow username' if @username == ''
      raise 'Unknow password' if @password == ''
      json = @network.post \
        '/login',
        type: 'm.login.password',
        user: @username,
        password: @password
      @access_token = json['access_token']
      save_token
    end

    def init_batch
      json = get "/sync?access_token=#{@access_token}"
      @next_batch = json['next_batch']
      save_batch
    end

    def sync
      init_batch if @next_batch.nil?
      @json = @network.get \
        '/sync',
        since: @next_batch,
        timeout: 10_000,
        access_token: @access_token
      @next_batch = @json['next_batch']
      save_batch
    end

    def error(res)
      json = JSON.parse res.body
      return json unless json.key? 'error'
      case json['errcode']
      when 'M_UNKNOWN_TOKEN' then login
      else raise json['error']
      end
    end

    def quit
      @run = false
      save_batch
    end

    def run
      while @run
        sync
        save_batch
        @event_method.each { |func| func.call self }
        sleep 1
      end
    end
  end
end
