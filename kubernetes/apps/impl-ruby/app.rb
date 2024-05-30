require 'net/http'
require 'openssl'
require 'uri'

def make_request(url, ca_cert_file = nil)
  uri = URI(url)
  http = Net::HTTP.new(uri.host, uri.port)

  if uri.scheme == 'https'
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER

    if ca_cert_file
      store = OpenSSL::X509::Store.new
      store.add_file(ca_cert_file)
      http.cert_store = store
    end
  end

  request = Net::HTTP::Get.new(uri)
  response = http.request(request)

  puts "STATUS: #{response.code}"
  puts "HEADERS:"
  response.each_header do |key, value|
    puts "  #{key}: #{value}"
  end
  # Printing the body is not necessary for this example
  # puts "BODY:"
  # puts response.body
rescue => e
  puts "Error making request: #{e.message}"
end

if ARGV.length < 1
  puts "Usage: ruby app.rb [URL] [optional: ca-certificate-file]"
  exit 1
end

url = ARGV[0]
ca_cert_file = ARGV[1]
make_request(url, ca_cert_file)
