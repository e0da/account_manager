# vim: set ft=ruby:

group :rspec do
  guard :rspec do
    watch(%r[^(spec/.+_spec\.rb)$]) # dirty hack because I haven't organized things well
    watch(%r[^lib/(.+)\.rb$])       { |m| "spec/#{m[1]}_spec.rb" }
    watch(%r[spec/spec_helper.rb])  { 'spec' }
    watch(%r[config])               { 'spec' }
    watch(%r[^lib/account_manager/app.rb]) { 'spec/requests' }
  end
end

group :frontend do
  guard 'compass' do
    watch(%r[^views/stylesheets/(.*)\.s[ac]ss])
  end
end
