require 'savon'
Savon::Request.logger = nil
Savon::Response.raise_errors = false

class ClickAndBuyGateway
  
  HeaderMapping = {
    :abo_definition_id => 'HTTP-X-ABODEFINITIONID',
    :actual_bdr_amount => 'HTTP_X_ACTUALBDRAMOUNT',
    :content_id => 'HTTP_X_CONTENTID',
    :fee_name => 'HTTP_X_FEENAME',
    :group_id => 'HTTP_X_GROUPID',
    :nation => 'HTTP_X_NATION',
    :price => 'HTTP_X_PRICE',
    :currency => 'HTTP_X_CURRENCY',
    :session_id => 'HTTP_X_SESSIONID',
    :subscription_id => 'HTTP_X_SUBSCRIPTIONID',
    :transaction_id => 'HTTP_X_TRANSACTION',
    :user_id => 'HTTP_X_USERID',
    :user_ip => 'HTTP_X_USERIP',
    :remote_addr => 'REMOTE_ADDR'
  }
  
  ParamMapping = {
    :first_name => 'cb_billing_FirstName',
    :middle_name => 'cb_billing_MiddleName',
    :last_name => 'cb_billing_LastName',
    :street => 'cb_billing_Street',
    :street2 => 'cb_billing_Street2',
    :zip => 'cb_billing_State',
    :city => 'cb_billing_ZIP',
    :province => 'cb_billing_City',
    :country => 'cb_billing_Nation',
    :id => 'j_bdr_id',
    :checksum => 'j_key',
    :user_id => 'jurnalo_id'
  }
  
  cattr_accessor :supported_countries, :supported_cardtypes, :homepage_url, :display_name, :logo_url
  attr_accessor :options
  
  # The countries the gateway supports merchants from as 2 digit ISO country codes
  self.supported_countries = [ 'AT', 'DE', 'CH', 'US' ]
      
  # The card types supported by the payment gateway
  self.supported_cardtypes = [ :visa, :master, :american_express, :discover]
      
  # The homepage URL of the gateway
  self.homepage_url = 'http://www.clickandbuy.com/'
  
  # The name of the gateway
  self.display_name = 'Click and Buy'
  
  self.logo_url = 'http://www.clickandbuy.com/'
  
  def initialize(options = {})
    requires!( options, :premium_links, :transaction_password, :merchant_id, :success_url, :error_url )
    @options = options
  end
  
  def success_url( transaction )
    options[:success_url]+'?result=success'+"&j_bdr_id=#{transaction.billing_record_id}&j_key=#{transaction.billing_record.checksum}"
  end
  
  def error_url( transaction )
    options[:error_url]+'?result=error&s=2&m='+transaction.message.to_s
  end
  
  def start( user, request )
    billing_record = user.billing_records.build( request.params[:billing_record] || {} )
    plink = options[:premium_links][ billing_record.plan_id ]
    return billing_record if plink.blank?
    billing_record.amount = plink[:price]
    billing_record.currency = plink[:currency]
    return billing_record unless billing_record.save
    puri = URI.parse( plink[:url] )
    puri.query = ""
    self.class::ParamMapping.each{ |key, value| 
      begin
        key_value = billing_record.send(key).to_s
        puri.query = puri.query + "#{value}=#{URI.encode(key_value)}&"
      rescue StandardError
      end
    }
    billing_record.premium_link = puri.to_s
    return billing_record
  end
  
  # First Handshake
  def authorize( request )
    set_authorize_transaction_data( request ) do | gateway_transaction |
      get_billing_record( gateway_transaction ) do | billing_record |
        gateway_transaction.message ||= :remote_addr_nok  unless remote_addr_ok?( gateway_transaction )
        gateway_transaction.message ||= :checksum_nok     unless checksum_ok?( gateway_transaction, billing_record.checksum )
        gateway_transaction.message ||= :jurnalo_id_nok   unless jurnalo_id_ok?( gateway_transaction, billing_record.user_id )
        gateway_transaction.message ||= :price_nok        unless price_ok?( gateway_transaction, billing_record.amount )
        gateway_transaction.message ||= :currency_nok     unless currency_ok?( gateway_transaction, billing_record.currency )
        gateway_transaction.message ||= :transaction_nok  unless transaction_ok?( gateway_transaction )
        gateway_transaction.message ||= :success
        gateway_transaction.message == :success ? billing_record.payment_authorized! : billing_record.payment_error!
      end
      gateway_transaction.message ||= :billing_record_nok 
    end
  end
  
  # Second Handshake
  # doing a SOAP Call Confirmation
  def confirm( user, request )
    set_confirm_transaction_data( user, request ) do | billing_record, bdr_id |
      client = Savon::Client.new("https://services.eu.clickandbuy.com/TMI/1.4/")
      response = client.is_bdrid_committed! do |soap|
        soap.namespace = "TransactionManager.Status"
        soap.action    = "TransactionManager.Status#isBDRIDCommitted"
        soap.input     = "isBDRIDCommitted"
        soap.body      = { "sellerID" => options[:merchant_id].to_s, "tmPassword" => options[:transaction_password].to_s, "slaveMerchantID" => "0", "BDRID" => bdr_id }
      end
      !response.soap_fault? && response.to_hash[:is_bdrid_committed_response][:return][:is_committed] 
    end
  end
  
  protected
  
  def set_confirm_transaction_data( user, request, &block )
    success = true
    billing_record = BillingRecord.find_by_id( param( request, :j_bdr_id ) )
    gateway_transaction = billing_record ? billing_record.gateway_transactions.find( :first, 
      :conditions => { :transaction_id => param( request, :BDRID ) }, :order => 'created_at DESC' ) : nil
    gateway_transaction.try( :checksum=, param( request, :j_key ) )
    success = ( gateway_transaction && billing_record &&
      billing_record.user_id == user.id &&
      checksum_ok?( gateway_transaction, billing_record.checksum ) &&
      billing_record.authorized?
      param(request, :result) == "success"
    )
    success = block.call( billing_record, gateway_transaction.transaction_id ) if success
    ( success ? billing_record.payment_confirmed! : billing_record.payment_error! ) if billing_record
    return success
  end
  
  def set_authorize_transaction_data( request, &block )
    gateway_transaction = GatewayTransaction.new
    self.class::HeaderMapping.keys.each do |key|
      gateway_transaction.send( "#{key}=", header( request, key ) )
    end
    gateway_transaction.billing_record_id = param( request, :j_bdr_id )
    gateway_transaction.checksum = param( request, :j_key )
    gateway_transaction.jurnalo_user_id = param( request, :jurnalo_id )
    block.call( gateway_transaction ) if gateway_transaction.ok?
    gateway_transaction.message ||= :response_nok
    gateway_transaction.save
    gateway_transaction
  end
  
  def get_billing_record( gateway_transaction, &block )
    block.call( gateway_transaction.billing_record ) if gateway_transaction.billing_record && gateway_transaction.billing_record.gateway_transactions.empty?
  end
  
  def price_ok?( gateway_transaction, expected_price )
    gateway_transaction.price == expected_price
  end
  
  def transaction_ok?( gateway_transaction )
    gateway_transaction.transaction_id && gateway_transaction.transaction_id != 0
  end
  
  def jurnalo_id_ok?( gateway_transaction, expected_jurnalo_id )
    gateway_transaction.jurnalo_user_id.to_s == expected_jurnalo_id.to_s
  end
    
  def checksum_ok?( gateway_transaction, expected_checksum )
    gateway_transaction.checksum == expected_checksum
  end
  
  def remote_addr_ok?( gateway_transaction )
    gateway_transaction.remote_addr.to_s[0,11] == '217.22.128.'
  end
  
  def param( request, key, type = :integer )
    val = request.params[ key ]
    type == :integer ? val.to_i : val
  end
  
  def header( request, key, type = :string )
    val = request.headers[ self.class::HeaderMapping[key] ]
    type == :integer ? val.to_i : val
  end
  
  private
  
  def requires!( *args )
    hash = args.shift
    valid = args.inject(true){ |v, arg| v = v && !hash[arg].blank? }
    raise 'Required Params Missing' unless valid
  end
  
end
