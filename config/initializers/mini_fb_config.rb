require 'mini_fb'
module FB
  
  Config = YAML::load( File.open( RAILS_ROOT + '/config/minifb.yml' ) )
  
  def self.api_key
    Config[RAILS_ENV]['fb_api_key']
  end
  
  def self.secret
    Config[RAILS_ENV]['fb_secret']
  end
  
  def self.app_id
    Config[RAILS_ENV]['fb_app_id']
  end
  
end