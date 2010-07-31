ActiveSupport::Cache::FileStore.class_eval do
  
  def read(name, options = nil)
    super
    file_name = real_file_path(name)
    expires = expires_in(options)
    if exist_without_instrument?(file_name, expires)
      File.open(file_name, 'rb') { |f| Marshal.load(f) }
    end
  end
  
  def exists?( name, options = nil)
    super
    exist_without_instrument?(real_file_path(name), expires_in(options))
  end
  
  protected
  
  def exist_without_instrument?(file_name, expires)
    File.exist?(file_name) && (expires <= 0 || Time.now - File.mtime(file_name) < expires)
  end
  
end

ActionController::Caching::Actions::ActionCachePath.class_eval do
  class << self
    def path_for(controller, options, infer_extension = true)
      new(controller, options).path
    end
  end
  
  # When true, infer_extension will look up the cache path extension from the request's path & format.
  # This is desirable when reading and writing the cache, but not when expiring the cache -
  # expire_action should expire the same files regardless of the request format.
  def initialize(controller, options = {}, infer_extension = true)
    if options.is_a?( Hash )
      if infer_extension
        extract_extension(controller.request) 
        options = options.reverse_merge(:format => @extension)
      end
      cache_key = options.delete(:cache_key)
    end
    path = controller.url_for(options).split('://').last
    normalize!( path )
    add_extension!(path, @extension)
    path << "/" << Array( cache_key ).collect{ |s| ( s.to_s[0] == ?@ ? controller.instance_variable_get( s ).try(:cache_key) : controller.params[s] ) || 'nil' }.join('-')
    @path = URI.unescape(path)
  end

  private
    def normalize!(path)
      path << 'index' if path[-1] == ?/
    end

    def add_extension!(path, extension)
      path << ".#{extension}" if extension and !path.ends_with?(extension)
    end
    
    def extract_extension(request)
      # Don't want just what comes after the last '.' to accommodate multi part extensions
      # such as tar.gz.
      @extension = request.path[/^[^.]+\.(.+)$/, 1] || request.cache_format
    end 
end

ActionController::Caching::Actions::ActionCacheFilter.class_eval do
  
  private
  
  def caching_allowed(controller)
    true
  end
  
end