guard 'compass' do
  watch(%r{^views/stylesheets/(.*)\.s[ac]ss})
end

guard 'rspec', :version => 2 do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$})     { |m| "spec/lib/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb')  { "spec" }
  watch('account_manager.rb') { 'spec/account_manager_spec.rb' }
end
