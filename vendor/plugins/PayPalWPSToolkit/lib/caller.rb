require 'httpclient'
require 'util'
require 'credentials'
# The module has a class and a wrapper method wrapping NET:HTTP methods to simplify calling PayPal APIs.

module PayPalWPSToolkit  
      
  class Pdt
    attr_accessor :params
    attr_accessor :success
    cattr_accessor :pdt_url
    @@pdt_url = PayPalWPSToolkit::Credentials.action_url
    
    
    def initialize(post)
      empty!
      post_back(post)
    end

    def success?
      @success
    end
           
    # reset the params hash 
    def empty!
      @params  = Hash.new         
    end    
    def get_params
      @params
    end
    def log(fname)
      info = ""
      @params.each_pair {|key,value| info << "#{key}=#{value}\n"}  
      @PayPalLog=PayPalWPSToolkit::Logger.getLogger(fname) 
      @PayPalLog.info info
    end
    
    def post_back(post_data)           
      client = HTTPClient.new 
      client.debug_dev = STDOUT if $DEBUG 
      client.ssl_config.verify_mode = nil 
      res =client.post(self.pdt_url, post_data)          
      response_array = res.body.content.split()     
      @success  = response_array[0].to_s == "SUCCESS"     
      response_array.each do  |x|
        if ! x.nil?
          key, value = x.split("=")
          if !value.nil?
            @params[key]=CGI.unescape(value)
          end
        end
       end       
    end
  end  
  
  class Ipn
    attr_accessor :params
    attr_accessor :ack
    attr_accessor :verified
    attr_accessor :invalid
    attr_accessor :success
    cattr_accessor :ipn_url
   
    @@ipn_url = "#{PayPalWPSToolkit::Credentials.action_url}?cmd=_notify-validate"
    def initialize(post)
      empty!
      post_back(post)
    end
    
    def acknowledge?
      @ack= @verified || @invalid
    end
               
    # reset the params hash 
    def empty!
      @params  = Hash.new         
    end    
    def get_params
      @params
    end
    def verified?
      @verified
    end
    def invalid?
      @invalid
    end
   
    def complete?
      status == "Completed"
    end
    def status
      @params['payment_status']
    end
    def log
      info = ""
      @params.each_pair {|key,value| info << "#{key}=#{value}\n"}  
      @PayPalLog=PayPalWPSToolkit::Logger.getLogger('paypal-ipn.log') 
      @PayPalLog.info info
    end
    
    def post_back(post_data)           
      client = HTTPClient.new 
      client.debug_dev = STDOUT if $DEBUG 
      client.ssl_config.verify_mode = nil 
      res =client.post(self.ipn_url, post_data)          
      raise StandardError.new("Faulty paypal result: #{res.body.content}") unless ["VERIFIED", "INVALID"].include?(res.body.content) 
      @verified=res.body.content == "VERIFIED"
      p " verified =#@verified}"
      @invalid=res.body.content == "INVALID"
      response_array = res.body.content.split() 
      response_array.each do  |x|
        if ! x.nil?
          key, value = x.split("=")
          if !value.nil?
            @params[key]=CGI.unescape(value)
          end
        end
       end       
    end
  end  
end  

