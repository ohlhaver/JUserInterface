module PayPalWPSToolkit
  
  class Credentials  
    
    cattr_accessor :action_url
    cattr_accessor :cert_path_root
    cattr_accessor :secure
    cattr_accessor :paypal_pub_cert_file
    cattr_accessor :app_pub_cert_file
    cattr_accessor :app_prv_key_file
    cattr_accessor :app_cert_id
    cattr_accessor :app_merchant_id
    cattr_accessor :app_pdt_id_token
    cattr_accessor :hosted_button_id
    cattr_accessor :button_pixels
    cattr_accessor :button_images
    cattr_accessor :app_pub_cert
    cattr_accessor :app_prv_key
    cattr_accessor :paypal_pub_cert
    
    def self.finalize!
      @@button_images ||= { 'en' => 'http://www.paypal.com/us_EN/i/btn/btn_buynow_LG.gif'.freeze, 
        'de' => 'http://www.paypal.com/de_DE/i/btn/btn_buynow_LG.gif'.freeze }
      @@cert_path_root ||= RAILS_ROOT+"/vendor/plugins/PayPalWPSToolkit/lib/cert"
      if @@secure
        @@app_pub_cert = File::read( self.cert_path_root + "/" + self.app_pub_cert_file )
        @@app_prv_key = File::read( self.cert_path_root + "/" + self.app_prv_key_file )
        @@paypal_pub_cert = File::read( self.cert_path_root + "/" + self.paypal_pub_cert_file )
      end
    end
    
    def self.button_image( locale )
      self.button_images[ locale.to_s ]
    end
    
    def self.button_pixel( locale )
      self.button_pixels[ locale.to_s ]
    end
    
  end
  
end