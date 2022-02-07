require 'socket'
require 'uri'

MimeType = {
  '.js' => 'application/javascript',
  '.json' => 'application/json',
  '.html' => 'text/html',
  '.png' => 'image/png',
  '.svg' => 'image/svg+xml',
}

def HTTPHeader (status_code, content_type = 'text/plain', extra = '')
  # HTTPHeader: return HTTP header based on given infomation
  status_msg = case status_code
               when 503
                 'Service Unavailable'
               when 404
                 'Not Found'
               when 200
                 'OK'
               end

  return <<~EOT.encode(crlf_newline: true)
    HTTP/1.1 #{status_code} #{status_msg}
    Content-Type: #{content_type}
    #{"#{extra}\n" if extra.to_s.empty?}
  EOT
end

module HTTPServer
  # HTTPServer: wrapper for TCPServer
  def self.start(port = PORT, &block)
    server = TCPServer.new('localhost', port)
    # add REUSEADDR option to prevent kernel from keeping the port
    server.setsockopt(:SOCKET, :REUSEADDR, true)

    begin
      Socket.accept_loop(server) do |sock, _|
        begin
          header = sock.readlines(chomp: true)
          next unless header.empty? # undefined method `split' for nil:NilClass

          Verbose.puts 'Received HTTP request header:', *header.map {|m| "> #{m}"}

          method, path, _ = header[0].split(' ', 3)
          uri = URI(path)
          params = URI.decode_www_form(uri.query.to_s).to_h

          yield sock, uri, params, method
        rescue Errno::EPIPE
        ensure
          sock.close
        end
      end
    ensure
      server.close
    end
  end
end
