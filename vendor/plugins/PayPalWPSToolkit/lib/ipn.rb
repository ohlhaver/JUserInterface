require 'cgi'
require 'net/http'
require 'net/https'
require 'active_support'
require 'util'
require 'credentials'
#--
# Copyright (c) 2005 Tobias Luetke
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++
module PayPalWPSToolkit
  # Parser and handler for incoming Instant payment notifications from paypal. 
  # The Example shows a typical handler in a rails application. Note that this
  # is an example, please read the Paypal API documentation for all the details
  # on creating a safe payment controller.
  #
  # Example
  #  
  #   class BackendController < ApplicationController
  #   
  #     def paypal_ipn
  #       notify = Paypal::Notification.new(request.raw_post)
  #   
  #       order = Order.find(notify.item_id)
  #     
  #       if notify.acknowledge 
  #         begin
  #           
  #           if notify.complete? and order.total == notify.amount
  #             order.status = 'success' 
  #             
  #             shop.ship(order)
  #           else
  #             logger.error("Failed to verify Paypal's notification, please investigate")
  #           end
  #   
  #         rescue => e
  #           order.status        = 'failed'      
  #           raise
  #         ensure
  #           order.save
  #         end
  #       end
  #   
  #       render :nothing
  #     end
  #   end
  class Notification
    attr_accessor :params
    attr_accessor :raw

    # Overwrite this url. It points to the Paypal sandbox by default.
    # Please note that the Paypal technical overview (doc directory)
    # speaks of a https:// address for production use. In my tests 
    # this https address does not in fact work. 
    # 
    # Example: 
    #   Paypal::Notification.ipn_url = http://www.paypal.com/cgi-bin/webscr
    #
    cattr_accessor :ipn_url
    @@ipn_url = 'https://www.beta-sandbox.paypal.com/cgi-bin/webscr'
    

    # Overwrite this certificate. It contains the Paypal sandbox certificate by default.
    #
    # Example:
    #   Paypal::Notification.paypal_cert = File::read("paypal_cert.pem")
    cattr_accessor :paypal_cert
   

    # Creates a new paypal object. Pass the raw html you got from paypal in. 
    # In a rails application this looks something like this
    # 
    #   def paypal_ipn
    #     paypal = Paypal::Notification.new(request.raw_post)
    #     ...
    #   end
    def initialize(post)
      empty!
      parse(post)
    end

    # Was the transaction complete?
    def complete?
      status == "Completed"
    end

    # When was this payment received by the client. 
    # sometimes it can happen that we get the notification much later. 
    # One possible scenario is that our web application was down. In this case paypal tries several 
    # times an hour to inform us about the notification
    def received_at
      Time.parse params['payment_date']
    end

    # Whats the status of this transaction?
    def status
      params['payment_status']
    end

    # Id of this transaction (paypal number)
    def transaction_id
      params['txn_id']
    end

    # What type of transaction are we dealing with? 
    #  "cart" "send_money" "web_accept" are possible here. 
    def type
      params['txn_type']
    end

    # the money amount we received in X.2 decimal.
    def gross
      params['mc_gross']
    end

    # the markup paypal charges for the transaction
    def fee
      params['mc_fee']
    end

    # What currency have we been dealing with
    def currency
      params['mc_currency']
    end
  
    # This is the item number which we submitted to paypal 
    def item_id
      params['item_number']
    end

    # This is the invocie which you passed to paypal 
    def invoice
      params['invoice']
    end   
    
    # This is the invocie which you passed to paypal 
    def test?
      params['test_ipn'] == '1'
    end

    # This is the custom field which you passed to paypal 
    def invoice
      params['custom']
    end
    
    def gross_cents
      (gross.to_f * 100.0).round
    end

    # This combines the gross and currency and returns a proper Money object. 
    # this requires the money library located at http://dist.leetsoft.com/api/money
    def amount
      return Money.new(gross_cents, currency) rescue ArgumentError
      return Money.new(gross_cents) # maybe you have an own money object which doesn't take a currency?
    end
    
    # reset the notification. 
    def empty!
      @params  = Hash.new
      @raw     = ""      
    end

   def log
      info = ""
      @params.each_pair {|key,value| info << "#{key}=#{value}\n"}  
      @PayPalLog=PayPalWPSToolkit::Logger.getLogger('paypal-ipn.log') 
      @PayPalLog.info info
   end

    # Acknowledge the transaction to paypal. This method has to be called after a new 
    # ipn arrives. Paypal will verify that all the information we received are correct and will return a 
    # ok or a fail. 
    # 
    # Example:
    # 
    #   def paypal_ipn
    #     notify = PaypalNotification.new(request.raw_post)
    #
    #     if notify.acknowledge 
    #       ... process order ... if notify.complete?
    #     else
    #       ... log possible hacking attempt ...
    #     end
    def acknowledge      
      payload =  raw
      
      uri = URI.parse(self.class.ipn_url)
      request_path = "#{uri.path}?cmd=_notify-validate"
      
      request = Net::HTTP::Post.new(request_path)
      request['Content-Length'] = "#{payload.size}"
      request['User-Agent']     = "PayPalRubyWPSToolkitV1.0.0"

      http = Net::HTTP.new(uri.host, uri.port)

      http.verify_mode    = OpenSSL::SSL::VERIFY_NONE unless @ssl_strict
      http.use_ssl        = true

      response = http.request(request, payload)
        
      raise StandardError.new("Faulty paypal result: #{response.body}") unless ["VERIFIED", "INVALID"].include?(response.body)
      response_array = response.body.split() 
      response_array.each do  |x|
        if ! x.nil?
          key, value = x.split("=")
          if !value.nil?
            @params[key]=CGI.unescape(value)
          end
        end
       end       
      
      response.body == "VERIFIED"
    end

    private
    
    # Take the posted data and move the relevant data into a hash
    def parse(post)
      @raw = post
      for line in post.split('&')    
        key, value = *line.scan( %r{^(\w+)\=(.*)$} ).flatten
        params[key] = CGI.unescape(value)
      end
    end

  end
end
