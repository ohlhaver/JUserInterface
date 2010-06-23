namespace :cache do
  
  desc 'Sweeps the file cache'
  task :clean => :environment do
    if Rails.cache.respond_to?( :cache_path )
      dirs = Dir[ "#{Rails.cache.cache_path}/views/*/api/*/" ]
      dirs.each do |dir|
        dir_list = Dir[ dir+'*/' ]
        if dir_list.any?
          delete_dir = dir + 'to_delete'
          FileUtils.mkdir_p( delete_dir )
          FileUtils.mv( dir_list, delete_dir )
          FileUtils.rm_rf( delete_dir )
        end
      end
    end
  end
  
end