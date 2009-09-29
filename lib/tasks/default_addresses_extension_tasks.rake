namespace :db do
  desc "Bootstrap your database for Spree."
  task :bootstrap  => :environment do
    # load initial database fixtures (in db/sample/*.yml) into the current environment's database
    ActiveRecord::Base.establish_connection(RAILS_ENV.to_sym)
    Dir.glob(File.join(DefaultAddressesExtension.root, "db", 'sample', '*.{yml,csv}')).each do |fixture_file|
      Fixtures.create_fixtures("#{DefaultAddressesExtension.root}/db/sample", File.basename(fixture_file, '.*'))
    end
  end
end

namespace :spree do
  namespace :extensions do
    namespace :default_addresses do
      desc "Copies public assets of the Default Addresses to the instance public/ directory."
      task :update => :environment do
        is_svn_git_or_dir = proc {|path| path =~ /\.svn/ || path =~ /\.git/ || File.directory?(path) }
        Dir[DefaultAddressesExtension.root + "/public/**/*"].reject(&is_svn_git_or_dir).each do |file|
          path = file.sub(DefaultAddressesExtension.root, '')
          directory = File.dirname(path)
          puts "Copying #{path}..."
          mkdir_p RAILS_ROOT + directory
          cp file, RAILS_ROOT + path
        end
      end  
    end
  end
end

desc "Imports last addresses as defaults"
task :get_default_addresses => :environment do
  User.find(:all).each do |user|
    orders_with_addresses = user.orders(:order => "created_at ASC").select{|o|
      o.bill_address && o.shipment && o.shipment.address
    }
    if last_order = orders_with_addresses.last
      puts "#{user.email}: Found addresses"
      bill_address = last_order.bill_address
      ship_address = last_order.shipment.address
      user.update_attribute(:bill_address_id, bill_address && bill_address.id)
      user.update_attribute(:ship_address_id, ship_address && ship_address.id)
    else
      puts "#{user.email}: Could not find any usefull addresses associated with user"
    end
  end
end