group :rspec do
  guard :rspec, :version => 2 do
    watch(%r[^(spec/.+_spec\.rb)$])
    watch(%r[^lib/(.+)\.rb$])       { |m| "spec/#{m[1]}_spec.rb" }
    watch(%r[spec/spec_helper.rb])  { 'spec' }
    watch(%r[config])               { 'spec' }
  end
end

group :frontend do
  guard 'compass' do
    watch(%r[^views/stylesheets/(.*)\.s[ac]ss])
  end
end
