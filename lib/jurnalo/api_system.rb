module Jurnalo
module ApiSystem
  
  def self.included( base )
    unless included_modules.include?( Jurnalo::ApiSystem::InstanceMethods )
      base.send( :include, Jurnalo::ApiSystem::InstanceMethods )
      base.send( :extend, Jurnalo::ApiSystem::ClassMethods )
      base.class_eval do
        alias_method_chain :verify_authenticity_token, :skip
        rescue_from StandardError, :with => :internal_server_error
        rescue_from ActiveRecord::RecordNotFound, :with => :record_not_found
        rescue_from InstanceMethods::API::InvalidApiKey,  :with => :api_key_invalid
        rescue_from InstanceMethods::API::InvalidRequest, :with => :api_request_invalid
        rescue_from InstanceMethods::API::RequiredAttributeMissing, :with => :api_required_attribute_missing
      end
    end
  end
  
  module InstanceMethods
    
    module API
      
      class InvalidApiKey < StandardError
      end
      
      class InvalidRequest < StandardError
      end
      
      class RequiredAttributeMissing < StandardError
      end
      
    end
    
    def index
      rxml_invalid_action
    end

    def create
      rxml_invalid_action
    end

    def show
      rxml_invalid_action
    end

    def update
      rxml_invalid_action
    end

    def destroy
      rxml_invalid_action
    end
    
    def verify_authenticity_token_with_skip
      verify_authenticity_token_without_skip unless params[:format] == 'xml'
    end
    
    def record_not_found( exception )
      respond_to do |format|
        flash.now[:error] = 'Record Not Found'
        format.html{ raise exception }
        format.xml{ render_xml_error_response( 'Record Not Found', 'entity.not.found', :not_found ) }
      end
    end
    
    def internal_server_error(exception)
      respond_to do |format|
         format.html{ raise exception }
         format.xml{ 
           logger.info( exception )
           exception.backtrace.each{ |x| logger.info( x ) }
           render_xml_error_response( 'Runtime Error' ) 
         }
      end
    end
    
    def api_key_invalid( exception )
      render_xml_error_response( exception.to_s, 'api.key.invalid', :not_acceptable )
    end
    
    def api_request_invalid( exception )
      render_xml_error_response( exception.to_s, 'api.request.invalid', :not_acceptable )
    end
    
    def api_required_attribute_missing( exception )
      render_xml_error_response( exception.to_s, 'api.required.attribute.blank', :not_acceptable )
    end
    
    def rxml_invalid_action
      render_xml_error_response( 'Unknown Api Action', 'api.action.invalid', :method_not_allowed )
    end
    
    def rxml_success( data, options = {} )
      action = options.delete(:action) || 'action'
      render_xml_success_response( data.id, "entity.#{action}.successful" )
    end
    
    def rxml_data( data, options = {} )
      include_pagination_data = options.delete( :with_pagination )
      pagination_results = options.delete( :pagination_results ) || data
      render_xml_success do |opts|
        data.to_xml( opts.merge( options ) )
        if include_pagination_data
          { 
            :total_pages => pagination_results.total_pages, 
            :next_page => pagination_results.next_page,
            :current_page => pagination_results.current_page,
            :previous_page => pagination_results.previous_page 
          }.to_xml( opts.merge( :root => 'pagination' ) )
          facets = Array.new
          if pagination_results.respond_to?( :facets )
            pagination_results.facets.each{ |key, value|
              value.each{ |fid, fcount|
                facets.push( { :filter => key, :value => fid, :count => fcount } )
              }
            }
          end
          facets.to_xml( opts.merge( :root => 'facets' ) )
        end
        yield( opts ) if block_given?
      end
    end
    
    def rxml_error( data, options = {}, &block )
      action = options.delete(:action) || 'action'
      render_xml_error( "entity.#{action}.failure", :unprocessable_entity ) do |opts|
        data.errors.to_xml( opts.merge( options ) )
        yield( opts ) if block_given?
      end
    end
    
    def render_xml_success( message = 'request.action.successful', status = :ok, &block )
      xml =  { :error => false, :message => message }.to_xml( :root => 'response', :dasherize => false ) do |x|
          x.tag!( 'data' ) do |y|
            block.call( :dasherize => false, :builder => y, :skip_instruct => true )
          end
        end
      render_xml_response( xml, status ) 
    end
    
    def render_xml_error( message = 'internal.server.error', status = :internal_server_error, &block )
      xml =  { :error => false, :message => message }.to_xml( :root => 'response', :dasherize => false ) do |x|
          x.tag!( 'data' ) do |y|
            block.call( :dasherize => false, :builder => y, :skip_instruct => true )
          end
        end
      render_xml_response( xml, status ) 
    end
    
    def render_xml_error_response( data, message = 'internal.server.error', status = :internal_server_error )
      render_xml_response( { :error => true, :message => message, :data => data }.to_xml( :root => 'response', :dasherize => false ), status )
    end
    
    def render_xml_success_response( data, message = 'request.action.successful', status = :ok )
      render_xml_response( { :error => false, :message => message, :data => data }.to_xml( :root => 'response', :dasherize => false ), status )
    end
    
    def render_xml_response( xml, status )
      render :xml => xml, :status => status
    end
    
    def api_request_validation
      return unless api_request?
      raise( API::InvalidRequest, 'HTTP POST request required' ) unless request.post?
      raise( API::InvalidApiKey, params[:api_key] ) unless admin?
      required_api_params_present!
    end
    
    def required_api_params_present!
      ( self.class.required_api_params[ params[:action].to_sym ] || {} ).each do |attribute|
        conditional_proc = self.class.required_api_conditions[ params[:action].to_sym ][ attribute ] 
        next unless conditional_proc.nil? || conditional_proc.call( params )
        raise API::RequiredAttributeMissing, attribute.to_s unless params.has_key?( attribute )
      end
    end
    
    protected( :required_api_params_present!, :verify_authenticity_token_with_skip, :render_xml_error_response, 
      :render_xml_success_response, :api_required_attribute_missing, :api_request_invalid, :api_key_invalid, 
      :record_not_found )
    
  end
  
  module ClassMethods
    
    def required_api_param( param_id, options = {} )
      unless method_defined?( :required_api_params= )
        cattr_accessor :required_api_params
        cattr_accessor :required_api_conditions
        self.required_api_params = {}
        self.required_api_conditions = {}
      end
      Array( options[:only] ).each do | action |
        self.required_api_params[ action.to_sym ] ||= []
        self.required_api_params[ action.to_sym ].push( param_id )
        self.required_api_conditions[ action.to_sym ] ||= {}
        self.required_api_conditions[ action.to_sym ][ param_id ] = options[:if]
      end
    end
    
    def required_api_params
      {}
    end
    
  end
  
end
end