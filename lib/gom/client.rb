require 'uri'
require 'net/http'
#require 'active_support'
require 'rexml/document'
require 'gom/client/version'
require 'json/pure'

module Gom
  
  class HttpError < StandardError
    attr_reader :response, :description 

    def initialize(http_response, description)
      @response    = http_response
      @description = description
    end

    def to_s
      "#{@response.code} #{@response.message} #{@description}"
    end
  end
  
  class Client
    attr_reader :root

    def initialize(gom_root = 'http://gom')
      @root = URI.parse(gom_root)
    end

    def retrieve(path_or_uri, redirect_limit=10)
      self.retrieve! path_or_uri, redirect_limit
      rescue Gom::HttpError => e
        return nil if e.response.code == "404"
        raise e
    end

    def retrieve!(path_or_uri, redirect_limit=10)
      uri      = path_or_uri.kind_of?(URI) ? path_or_uri : URI.parse("#{@root}#{path_or_uri}")
      response = Net::HTTP.new(uri.host, uri.port).request_get(uri.path, {"Accept" => "application/json" })

      begin
        if response.kind_of?(Net::HTTPSuccess)
          return JSON.parse(response.body, symbolize_names: true)
        end
      rescue StandardError => e
        raise HttpError.new(response, "#{e} -- could not parse body: '#{response.body}'")
      end
      
      raise "too many redirects" if (redirect_limit == 0 && response.kind_of?(Net::HTTPRedirection))
      return Gom::retrieve(response['location'], redirect_limit - 1) if response.kind_of?(Net::HTTPRedirection)
      raise HttpError.new(response, "while GETting #{uri.path}")
    end

    def destroy!(path_or_uri)
      uri      = path_or_uri.kind_of?(URI) ? path_or_uri  : URI.parse("#{@root}#{path_or_uri}")
      response = Net::HTTP.new(uri.host, uri.port).delete(uri.path)
      
      return true if response.kind_of?(Net::HTTPSuccess)
      raise HttpError.new(response, "while DELETEing #{uri.path}")
    end

    def destroy(uri)
      self.destroy! uri
      rescue Gom::HttpError => e
        return nil if e.response.code == "404"
        raise e
    end

    def create!(path_or_uri, attributes={})
      uri          = path_or_uri.kind_of?(URI) ? path_or_uri : URI.parse("#{@root}#{path_or_uri}")
      request_body = attributes_to_xml attributes
      headers      = { 'Content-Type' => 'application/xml' }
      response     = Net::HTTP.new(uri.host, uri.port).request_post(uri.path, request_body, headers)
      
      return URI.parse(response['location']).path if response.kind_of?(Net::HTTPRedirection)
      raise HttpError.new(response, "while CREATEing #{uri.path}")
    end
    
    def update!(path_or_uri, hash_or_text=nil)
      uri = path_or_uri.kind_of?(URI) ? path_or_uri : URI.parse("#{@root}#{path_or_uri}")

      if is_attribute?(uri.path)
          raise "update attribute call must include value" if hash_or_text.nil?
          raise "update attribute value must be a string" unless hash_or_text.kind_of?(String)
          response_format              = "text/plain"
          if hash_or_text != ""
            doc                          = REXML::Document.new
            attr_node                    = doc.add_element 'attribute'
            attr_node.attributes['type'] = 'string';
            attr_node.text               = hash_or_text
            request_body                 = doc.to_s
            headers  = { 'Content-Type' => 'application/xml',
                         'Accept'       => response_format }
          else
            request_body                 = "attribute=#{hash_or_text}&type=string"
            headers  = { 'Content-Type' => 'application/x-www-form-urlencoded',
                         'Accept'       => response_format }
          end
      else
          raise "update node values must be a hash of attributes" unless hash_or_text.nil? or hash_or_text.kind_of?(Hash) 
          request_body = attributes_to_xml hash_or_text || {}
          response_format = "application/json"
          headers  = { 'Content-Type' => 'application/xml',
                       'Accept'       => response_format }
      end

      #headers  = { 'Content-Type' => 'application/xml',
      #             'Accept'       => response_format }

      response = Net::HTTP.new(uri.host, uri.port).request_put(uri.path, request_body, headers)
      
      return response.body if response.kind_of?(Net::HTTPSuccess) && response_format == "text/plain"
      if response.kind_of?(Net::HTTPSuccess) && response_format == "application/json"
        return HashWithIndifferentAccess.new(ActiveSupport::JSON.decode(response.body))
      end
      raise HttpError.new(response, "while PUTting #{uri.path}")
    end
    alias update update!

    # supports stored and posted scripts
    def run_script(options={})
      path   = options[:path]   || nil
      script = options[:script] || nil
      params = options[:params] || {}
      
      raise ArgumentError, "must provide script OR path" if (path.nil? && script.nil?)
      raise ArgumentError, "must not provide script AND path" if (path && script)
      
      my_params = params.keys.zip(params.values).map {|k,v| "#{k}=#{v}"}
      
      if my_params.size > 0
        url = URI.parse("#{@root}/gom/script-runner#{path}?#{my_params.join('&')}")
      else
        url = URI.parse("#{@root}/gom/script-runner#{path}")
      end
      
      if script
        request = Net::HTTP::Post.new(url.to_s)
        request.set_content_type "text/javascript"
        response = Net::HTTP.start(url.host, url.port) do |http| 
          http.request(request, script)
        end
      else
        request  = Net::HTTP::Get.new(url.to_s)
        response = Net::HTTP.start(url.host, url.port) do |http| 
          http.request(request)
        end
      end
      
      return response if response.kind_of?(Net::HTTPSuccess)
      raise HttpError.new(response, "while executing server-side-script:\n#{response.body}")
    end

    # supports anonymous and named observers
    def register_observer(options={})
      name         = options[:name]         || nil
      callback_url = options[:callback_url] || nil
      node         = options[:node]         || nil
      filters      = options[:filters]      || {}
      format       = options[:format]       || "application/json"
      
      raise ArgumentError, "callback_url must not be nil" if callback_url.nil?
      raise ArgumentError, "node must not be nil" if node.nil?
      raise ArgumentError, "invalid format" unless ['application/json', 'application/xml'].include?(format)
      
      url       = URI.parse("#{@root}/gom/observer#{node}")
      form_data = { 'callback_url' => callback_url,
                    'accept'       => format }
      form_data.merge!(filters)
      
      if name
        observer_url = url.path.gsub(/\:/,'/')
        my_uri       = "#{observer_url}/.#{name}"
        destroy my_uri
        
        form_data['observed_uri'] = "#{node}"
        update(my_uri, form_data)
      else
        request = Net::HTTP::Post.new(url.path)
        request.set_form_data(form_data)
        response = Net::HTTP.new(url.host, url.port).start do |http|
          http.request(request)
        end
        my_uri = URI.parse(response['location']).path
      end
      my_uri
    end

    private

      def is_attribute?(the_path)
        not the_path.index(":").nil?
      end

      def attributes_to_xml(hash={})
        doc  = REXML::Document.new
        node = doc.add_element 'node'
        hash.each do | key, value |
          attrib = node.add_element 'attribute'
          attrib.attributes['name'] = key
          attrib.text = value
        end
        doc.to_s
      end

  end
end
