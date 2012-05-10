## Downloading ##

    git clone https://github.com/justinforce/account_manager

## Configuring ##

    bundle
    compass compile

### Config File ###

Edit `config/production.example.yml` to fit your environment.

## Running ##

### Production ###

    RAKE_ENV=production passenger start

or

    RAKE_ENV=production rackup

### Development ###

    rake ladle:start & rackup

## Testing ##

    rspec

or
    guard -g rspec

or just

    guard

## Copyright ##

Copyright (c) 2012 Justin Force
Licensed under the MIT License
