
#
#  Defensio-Ruby
#  Written by the Defensio team at Websense, Inc.
#

require 'rubygems'
require 'httparty'
require 'uri'
require 'json'

class Defensor
  require 'defensor/cattr'
  require "defensor/version"
  include Version

  class NoApiKeyException < Exception; end
  class NoContentException < Exception; end
  class NoSignatureException < Exception; end

  cattr_accessor 'api_key'
  ALLOWED_OPTIONS = [:type, :platform, "author-email", "author-ip", :content, :signature]

  # You shouldn't modify these values unless you really know what you are doing. And then again...
  API_VERSION   = 2.0
  API_HOST      = "http://api.defensio.com"

  # You should't modify anything below this line.
  LIB_VERSION   = Defensor::VERSION
  ROOT_NODE     = "defensio-result"
  FORMAT        = :json
  USER_AGENT    = "Defensor #{LIB_VERSION}"
  CLIENT        = "Defensor | #{LIB_VERSION} | Oleg Bovykin | oleg.bovykin@gmail.com"
  KEEP_ALIVE    = false

  attr_accessor :options, :signature

  include HTTParty
  format FORMAT
  base_uri API_HOST

  def self.respond(response)
    [response.code, response[ROOT_NODE]]
  end

  # Get information about the api key
  def self.get_user
    respond get(api_path)
  end

  def self.api_path(action = nil, id = nil)
    path = "/#{API_VERSION}/users/#{@@api_key}"
    path += "/#{action}" if action
    path += "/#{id}" if id
    path += ".#{FORMAT}"
  end

  # Get basic statistics for the current user
  # @return [Array] An array containing 2 values: the HTTP status code & a Hash with the values returned by Defensio
  def self.get_basic_stats
    respond get(api_path("basic-stats"))
  end

  # Get more exhaustive statistics for the current user
  # @param [Hash] data The parameters to be sent to Defensio. Keys can either be Strings or Symbols
  # @return [Array] An array containing 2 values: the HTTP status code & a Hash with the values returned by Defensio
  def self.get_extended_stats(data)
    result = get(api_path("extended-stats"), :query => data)
    code = result.code
    result = result[ROOT_NODE]

    0.upto(result["data"].size - 1) do |i|
      result["data"][i]["date"] = Date.parse(result["data"][i]["date"])
    end

    [code, result]
  end

  # Filter a set of values based on a pre-defined dictionary
  def self.post_profanity_filter(data)
    respond post(api_path("profanity-filter"), :body => data)
  end

  def self.parse_body(str)
    if FORMAT == :json
      return JSON.parse(str)[ROOT_NODE]
    else
      raise(NotImplementedError, "This library doesn't support this format: #{FORMAT}")
    end
  end

  # Takes the request object (Rails, Sinatra, Merb) of an async request callback and returns a hash
  # containing the status of the document being analyzed.
  # @param [ActionController::Request, Sinatra::Request, String] request The request object created after Defensio POSTed to your site, or a string representation of the POST data.
  # @return [Hash] Status of the document
  def self.handle_post_document_async_callback(request)
    if request.is_a?(String)
      data = request
    elsif request.respond_to?(:body) && request.body.respond_to?(:read)
      data = request.body.read
    else
      raise ArgumentError, "Unknown request type: #{request.class}"
    end

    Defensor.parse_body(data)
  end

  def initialize(*options)
    check_key
    @options = options[0].reject {|k, v| !(ALLOWED_OPTIONS.include? k)}
    @signature = @options['signature'] if @options['signature']
  end

  def check_key
    raise NoApiKeyException if @@api_key.nil? || @@api_key.empty?
  end

  def check_document
    raise NoContentException if content.nil? || content.empty?
  end

  def content
    @options[:content]
  end

  # Create and analyze a new document
  # @param [Hash] data The parameters to be sent to Defensio. Keys can either be Strings or Symbols
  # @return [Array] An array containing 2 values: the HTTP status code & a Hash with the values returned by Defensio
  def post_document
    check_document
    response = Defensor.post(Defensor.api_path("documents"), :body => { :client => CLIENT }.merge(@options))
    status = response[ROOT_NODE]["status"]
    @signature = response[ROOT_NODE]["signature"] if status == "success"
    Defensor.respond response
  end

  # Get the status of an existing document
  # @param [String] signature The signature of the document to retrieve
  # @return [Array] An array containing 2 values: the HTTP status code & a Hash with the values returned by Defensio
  def get_document(signature=nil)
    @signature ||= signature
    if @signature
      Defensor.respond Defensor.get(Defensor.api_path("documents", @signature))
    else
      raise NoSignatureException
    end
  end

  # Modify the properties of an existing document
  # @param [String] signature The signature of the document to modify
  # @param [Hash] data The parameters to be sent to Defensio. Keys can either be Strings or Symbols
  # @return [Array] An array containing 2 values: the HTTP status code & a Hash with the values returned by Defensio
  def put_document(signature=nil, data)
    @signature ||= signature
    if @signature
      Defensor.respond Defensor.put(Defensor.api_path("documents", @signature), :body => data)
    else
      raise NoSignatureException
    end
  end

end

