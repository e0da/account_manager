Gevirtz Account Manager
=======================

[![Build Status](https://secure.travis-ci.org/justinforce/account_manager.png?branch=master)](https://travis-ci.org/justinforce/account_manager)
[![Dependency Status](https://gemnasium.com/justinforce/account_manager.png)](https://gemnasium.com/justinforce/account_manager)
[![Code Climate](https://codeclimate.com/github/justinforce/account_manager.png)](https://codeclimate.com/github/justinforce/account_manager)

Download and Setup
------------------

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

### Development ###

The required custom schema for Ladle is provided. If you need to modify and
rebuild it, read on.

_Note: I have found that some of the sources referred to by this Maven
build are hosted at m2.safehaus.org, which has NEVER responded to an
HTTP request from me, so to get this to work I had to first add this to
my `/etc/hosts` file._

    127.0.0.1 m2.safehaus.org # redirect these requests to localhost

Then just run this to build the schema. The development environment already
knows where to look to find it.

    rake ladle:schema

Running
-------

### Production ###

    sudo start account

### Development ###

    rake start

Testing
-------

    rspec

_Note: On my fast computer, some of the specs will fail on the first pass
because Ladle takes too long to start. If you get a few failures related to
directory operations, **don't panic**. Just run the specs again and see if they
pass. Watch for the telltale notification that the server took more than 15
seconds to start._

License
-------

Licensed under the MIT License. See `LICENSE`.
