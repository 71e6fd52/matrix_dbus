module MatrixDBus
  # DBus
  class Matrix2DBus < DBus::Object
    attr_reader :matrix

    def initialize(*args)
      @matrix = MatrixDBus::Matrix.new
      super
    end

    def run
      Thread.new do
        begin
          @matrix.run
        rescue RestClient::Exception => e
          puts e
          puts e.response.body
          retry
        end
      end
    end

    def self.return(info)
      return ['{}'] if info.nil?
      return ['{}'] if info.empty?
      [JSON.pretty_generate(info)]
    end

    # rubocop:disable Metrics/BlockLength
    dbus_interface 'org.dastudio.matrix' do
      %i[post put get delete].each do |way|
        dbus_method way, 'in url:s, in args:s, out res:s' do |url, args|
          args = '{}' if args == ''
          args = JSON.parse args
          if %i[get delete].include? way
            args[:access_token] = @matrix.access_token
          elsif %i[post put].include? way
            url = URI(url)
            url.query = URI.encode_www_form access_token: @matrix.access_token
            url = url.to_s
          else raise 'Connot raise'
          end
          begin
            Matrix2DBus.return @matrix.network.method(way).call(url, args)
          rescue RestClient::Exception => e
            puts e
            puts e.response.body
          end
        end
      end

      dbus_method :post_raw, 'in url:s, in body:s, out res:s' do |url, body|
        begin
          data = Base64.decode64 body
          Matrix2DBus.return @matrix.network.post_raw(url, data)
        rescue RestClient::Exception => e
          puts e
          puts e.response.body
        end
      end

      dbus_method :upload_file, 'in file:s, out mxc:s' do |file|
        url = URI('/upload')
        url.query = URI.encode_www_form access_token: @matrix.access_token
        url = url.to_s
        begin
          File.open(file, 'rb') do |f|
            Matrix2DBus.return @matrix.network.post_raw(url, f)
          end
        rescue RestClient::Exception => e
          puts e
          puts e.response.body
        end
      end

      %i[
        all
        account_data
        to_device
        presence
        rooms
        leave
        join
        invite
        device_lists
        changed
        left
      ].each do |name|
        dbus_signal name, 'json:s'
      end
    end
  end
end
