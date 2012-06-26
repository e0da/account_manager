$: << 'lib'

require 'account_manager/app'

# Compass Configuration

# require 'grid-coordinates'

# Configuration to use when running within Sinatra
project_path          = Sinatra::Application.root

# HTTP paths
http_path             = '/'
http_stylesheets_path = '/stylesheets'
http_images_path      = '/images'
http_javascripts_path = '/javascripts'

# File system locations
css_dir               = 'public/stylesheets'
sass_dir              = 'views/stylesheets'
images_dir            = 'public/images'
javascripts_dir       = 'public/javascripts'

# Syntax preference
preferred_syntax      = :sass

# Determine whether Compass generates relative or absolute paths
relative_assets       = false

# Determines whether line comments should be added to compiled css for easier debugging
line_comments         = true

# CSS output style - :nested, :expanded, :compact, or :compressed
output_style          = :nested
