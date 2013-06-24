notification :off

group :rspec, all_after_pass: true, all_on_start: true do
  guard :rspec do
    watch(%r[^lib/(.+)\.rb$])       { |m| "spec/#{m[1]}_spec.rb" }
    watch(%r[^spec/.*_spec\.rb$])
    watch(%r[spec/spec_helper.rb])  { 'spec' }
    watch(%r[config])               { 'spec' }
    watch(%r[^lib/account_manager/app.rb]) { 'spec' }
  end
end

group :frontend do
  guard 'compass' do
    watch(%r[^views/stylesheets/(.*)\.s[ac]ss])
  end
end

# vim: set ft=ruby:
