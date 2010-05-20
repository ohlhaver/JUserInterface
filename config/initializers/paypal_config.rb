require 'credentials'
ppc = PayPalWPSToolkit::Credentials
if RAILS_ENV.to_sym == :production
  ppc.action_url            = "https://www.paypal.com/de/cgi-bin/webscr".freeze
  ppc.app_merchant_id       = "RDPKJYN9VH9NS".freeze
  ppc.app_pdt_id_token      = "gzSXujusdz8vo8SPeA5zp1z4EZszKS2dw3WMPFHzi3xwDe0D3RCQNDMzr0q".freeze
  ppc.hosted_button_id      = "BN346RXUD76GL".freeze
  ppc.button_images         =  { 'de' => 'https://www.paypal.com/de_DE/DE/i/btn/btn_paynowCC_LG.gif'.freeze, 
    'en' => 'https://www.paypal.com/en_US/DE/i/btn/btn_paynowCC_LG.gif'.freeze }
  ppc.button_pixels         =  { 'de' => 'https://www.paypal.com/de_DE/i/scr/pixel.gif'.freeze, 
    'en' => 'https://www.paypal.com/en_US/i/scr/pixel.gif'.freeze }
else
  ppc.action_url            = "https://www.sandbox.paypal.com/cgi-bin/webscr".freeze
  ppc.app_merchant_id       = "7WT4UHP87PDHG".freeze
  ppc.app_pdt_id_token      = "0LbzH1rHoMnFFbWhZqBGl0IL10tuBEuAYa5Tw50wcYOfY1WKGvSHWSabazu".freeze
  ppc.hosted_button_id      = "9BSGFDSEJCYYE".freeze
  ppc.button_images         =  { 'de' => 'https://www.paypal.com/de_DE/DE/i/btn/btn_paynowCC_LG.gif'.freeze, 
    'en' => 'https://www.paypal.com/en_US/DE/i/btn/btn_paynowCC_LG.gif'.freeze }
  ppc.button_pixels         =  { 'de' => 'https://www.paypal.com/de_DE/i/scr/pixel.gif'.freeze, 
    'en' => 'https://www.paypal.com/en_US/i/scr/pixel.gif'.freeze }
end
require 'caller'
#require 'EWPServices'
