guard 'compass' do
  watch(%r{^views/stylesheets/(.*)\.s[ac]ss})
end

guard 'rspec', cli: '--format nested' do
  watch(/^spec|lib|config|account_manager.rb/) { 'spec' }
end
