# Gevirtz Account Manager #

## Download and Setup ##

    git clone https://github.com/justinforce/account_manager
    cd account_manager
    bundle
    rake

Simply running `rake` will run the recommended tasks for a setup on Ubuntu. For
more granular control, check out `rake -T`. As a minimum, you're going to want
to run `rake css` to build the stylesheets before running the app.

### Config File ###

Copy `config/production.example.yml` to `config/production.yml` and edit it to
fit your environment.

### For Development ###

You need to build the custom schema for Ladle.

_Note: I have found that some of the sources referred to by this Maven
build are hosted at m2.safehaus.org, which has NEVER responded to an
HTTP request from me, so to get this to work I had to first add this to
my `/etc/hosts` file._

    127.0.0.1 m2.safehaus.org # redirect these requests to localhost

Then just run this to build the schema. The development environment already
knows where to look to find it.

    rake ladle:schema

## Running ##

### Production ###

    sudo start account

### Development ###

    rake start

## Testing ##

    rspec

## Copyright ##

Copyright (c) 2012 Justin Force

Licensed under the MIT License
