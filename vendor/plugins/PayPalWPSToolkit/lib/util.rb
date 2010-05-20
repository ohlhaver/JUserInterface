require 'log4r'
require 'singleton'
# The module has a classes and a class method to intialize a logger and to specify formatting style using log4r library. 
module PayPalWPSToolkit
# Class has a class method which returs the logger to be used for logging.
# Wheneve IPN notification is received from PayPal, the IPN details will be logged to a file (filename paypal-ipn.log passed to getLogger method) under logs directroy.
class Logger  
    include Singleton
    cattr_accessor :MyLog
    def self.getLogger(filename)    
     
      @@MyLog = Log4r::Logger.new("paypallog")
      # note: The path prepended to filename is based on Rails path structure. 
      Log4r::FileOutputter.new('paypal_log',
                       :filename=> RAILS_ROOT + "/script/../config/../log/#{filename}",
                       :trunc=>false,
                       :formatter=> MyFormatter)
      @@MyLog.add('paypal_log')
      return @@MyLog
      end  
  end
# Class and method to redfine the log4r formatting.
class MyFormatter < Log4r::Formatter
    def format(event)
      buff = Time.now.strftime("%a %m/%d/%y %H:%M %Z")
      buff += " - #{Log4r::LNAMES[event.level]}"
      buff += " - #{event.data}\n"
    end
  end    
def hash2cgiString(h)
      h.map { |a| a.join('=') }.join('&') 
end
end