# Cheflow

A command line tool for managing Chef Environments using Berkshelf and the Node Cookbook Pattern.

> TLDR of the Node Cookbook Pattern; You have one top level cookbook that is locked to a Chef
Environment. One node per Chef Environment. This Chef Environment is named
`node_{application_name}_{environment_name}` (i.e. `node_myface_dev`).

Huge thanks go to [Jamie Winsor](https://github.com/reset) who coined the Environment Cookbook
pattern and created the excellent [Berkflow](https://github.com/reset/berkflow) gem that this Gem is
based upon and inspired by.

For the full details, read COOKBOOKS.md.


## Requirements

* [ChefDK](http://getchef.com/downloads/chef-dk) >= 0.2.0


## Installation

Install Cheflow into the ChefDK

    $ chef gem install cheflow


## Workflow

The Cheflow workflow is predominantly based on the current Cookbook version, which determines
whether to apply version locks from Berksfile.lock to the production environment or not.

### Development Releases

If the version's patch number is an odd one, ie. a dev release, then the environment should be
specified. If no environment is specified, then it will default to `development`. Cheflow will not
allow you to lock a development release to production, even if you specify it.

#### Create a new development version of a Node cookbook

- Bump the dev version. (eg. 1.0.0 to 1.0.1)
- Update Berkshelf: `berks install`.
- Upload new unfrozen version: `berks upload COOKBOOK --no-freeze`.
- Apply new version to the given Node environment: `berks apply ENVIRONMENT`

Equivalent Cheflow command:

    cheflow up [ENVIRONMENT]

Default environment is `development`.

#### Update development version of a Node cookbook

- Upload new unfrozen version: `berks upload COOKBOOK --no-freeze`.

Cheflow command:

    cheflow up [ENVIRONMENT]

Default environment is `development`.

### Production Releases

If the version's patch number is an even one. ie. a production release, then the environment is
assumed to be `production`. You can specify any other environment.

- Upload new frozen version
- Apply frozen version

Cheflow command:

    cheflow release [ENVIRONMENT]

Default environment is `production`.


## Usage

    $ cheflow help



## Contributing

1. Fork it ( https://github.com/joelmoss/cheflow/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
