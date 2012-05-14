## Downloading ##

    git clone https://github.com/justinforce/account_manager

## Configuring ##

    bundle
    compass compile

### Config File ###

Edit `config/production.example.yml` to fit your environment.

### For Development ###

You need to build the custom schema for Ladle.

_Note: I have found that some of the sources referred to by this Maven
build are hosted at m2.safehaus.org, which has NEVER responded to an
HTTP request from me, so to get this to work I had to first add this to
my `/etc/hosts` file._

    127.6.6.6 m2.safehaus.org

Then just run this to build the schema. The development environment already
knows where to look to find it.

    cd support/gevirtz_schema
    mvn clean && mvn package


## Running ##

### Production ###

    RAKE_ENV=production rake server:start

### Development ###

    rake server:start

## Testing ##

    rspec

## Copyright ##

Copyright (c) 2012 Justin Force

Licensed under the MIT License
