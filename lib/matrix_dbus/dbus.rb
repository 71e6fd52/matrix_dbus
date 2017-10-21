module MatrixDBus
  # DBus
  class Matrix2DBus < DBus::Object
    attr_reader :matrix

    def initialize(*args)
      @matrix = MatrixDBus::Matrix.new
      super
    end

    def run
      Thread.new { @matrix.run }
    end

    # rubocop:disable Metrics/BlockLength
    dbus_interface 'org.dastudio.matrix' do
      %i[post put].each do |way|
        dbus_method way, 'in url:s, in args:s, out res:s' do |url, args|
          args = '{}' if args == ''
          args = JSON.parse args
          url = URI(url)
          url.query = URI.encode_www_form access_token: @matrix.access_token
          url = url.to_s
          begin
            [@matrix.network.method(way).call(url, args).to_json]
          rescue RestClient::Exception => e
            puts e
            puts e.response.body
          end
        end
      end

      %i[get delete].each do |way|
        dbus_method way, 'in url:s, in args:s, out res:s' do |url, args|
          args = '{}' if args == ''
          args = JSON.parse args
          args[:access_token] = @matrix.access_token
          begin
            [@matrix.network.method(way).call(url, args).to_json]
          rescue RestClient::Exception => e
            puts e
            puts e.response.body
          end
        end
      end

      dbus_method :post_raw, 'in url:s, in body:s, out res:s' do |url, body|
        begin
          [@matrix.network.post_raw(url, Base64.decode64(body)).to_json]
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
