#!/usr/bin/ruby
#
# Copyright 2017 Istio Authors
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

require 'webrick'
require 'json'
require 'net/http'

if ARGV.length < 1 then
    puts "usage: #{$PROGRAM_NAME} port"
    exit(-1)
end

port = Integer(ARGV[0])

server = WEBrick::HTTPServer.new :BindAddress => '0.0.0.0', :Port => port

trap 'INT' do server.shutdown end

server.mount_proc '/health' do |req, res|
    res.status = 200
    res.body = {'status' => 'Details is healthy'}.to_json
    res['Content-Type'] = 'application/json'
end

server.mount_proc '/details' do |req, res|
    pathParts = req.path.split('/')
    headers = get_forward_headers(req)

    begin
        begin
          id = Integer(pathParts[-1])
        rescue
          raise 'please provide numeric product id'
        end
        details = get_book_details
        res.body = details
        res['Content-Type'] = 'text/plain'
    rescue => error
        res.body = {'error' => error}.to_json
        res['Content-Type'] = 'application/json'
        res.status = 400
    end
end

# TODO: provide details on different books.
def get_book_details
         # '<h4 class="text-center text-primary">Book Details - v2</h4>
    return '<h4 class="text-center text-primary">Book Details</h4>
            <dl>
              <dt>Type:</dt> Type
              <dt>Pages:</dt> Pages
              <dt>Publisher:</dt> Publisher
              <dt>Language:</dt> Language
              <dt>ISBN-10:</dt> ISBN-10
              <dt>ISBN-13:</dt> ISBN-13
            </dl>'
end

def get_forward_headers(request)
  headers = {}
  incoming_headers = [ 'x-request-id',
                       'x-b3-traceid',
                       'x-b3-spanid',
                       'x-b3-parentspanid',
                       'x-b3-sampled',
                       'x-b3-flags',
                       'x-ot-span-context'
                     ]

  request.each do |header, value|
    if incoming_headers.include? header then
      headers[header] = value
    end
  end

  return headers
end

server.start
