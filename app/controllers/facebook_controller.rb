require 'pp'

class FacebookController < ApplicationController
  
  jurnalo_login_required :except => [ :login, :callback, :callback2 ]
  before_filter :require_no_user
  
  def login
    display = mobile_device? ? 'wap' : 'page'
    callback = params[:p] == '1' ? "/fb/callback2": "/fb/callback"
    redirect_to MiniFB.oauth_url(FB.app_id, JUserApp + callback, :scope=> "email", :display => display)
  end
  
  # Profile looks like
  #
  # {"name"=>"Ram Singla",
  #  "timezone"=>5.5,
  #  "id"=>"680501499",
  #  "gender"=>"male",
  #  "first_name"=>"Ram",
  #  "link"=>"http://www.facebook.com/ram.singla",
  #  "verified"=>true,
  #  "last_name"=>"Singla",
  #  "email"=>"ram.singla@gmail.com",
  #  "updated_time"=>"2010-01-23T03:25:01+0000"}
  #
  def callback
    code = CGI.unescape(params['code']) # Facebooks verification string
    unless code
      redirect_to login_path
      return
    end
    access_token_hash = MiniFB.oauth_access_token( FB.app_id, JUserApp + "/fb/#{self.action_name}", FB.secret, code )
    access_token = access_token_hash['access_token']
    profile = MiniFB.get( access_token, 'me', :type => nil )
    u = User.find_or_new_fb_user( profile )
    # Scenario #1: New User
    if u.new_record? && u.save
      flash[:notice] = I18n.t('user.account.registration_success')
    elsif u.new_record?
      flash[:error] = u.errors.full_messages.join('<br/>')
      redirect_to login_path
    end
    # Scenario #2: User
    session[:fb] = access_token
    service_url = if !u.power_plan? && params[:p] == '1'
      JUserApp + power_upgrade_path( :id => :paypal )
    else
      cas_service_url( default_service )
    end
    redirect_to CASClient::Frameworks::Rails::Filter.client.login_url+"?service=#{CGI.escape(service_url)}&u=#{u.facebook_uid}&fb=1&p=#{u.fb_auth_digest}&s=#{Authlogic::Random.hex_token}"
    rescue Exception => exception
    flash[:error] = I18n.t('jurnalo.login.facebook_failure')
    logger.info( exception.to_s + "\n" + exception.backtrace.join("\n") )
    redirect_to login_path
  end
  
  def callback2
    params[:p] = '1'
    callback
  end
  
end
