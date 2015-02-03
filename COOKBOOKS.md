## Cookbooks

Each cookbook has a pattern applied to it, which is one of Library, Application, or Node, and every
cookbook should reside in its own Git repository.


### Library Cookbooks

This is the most basic building block of Cookbooks. These types of cookbooks are reusable and are
mixed into other cookbooks to enhance them by:

  - Adding LWRPs that abstract common functionality
  - Including Libraries that add Ruby modules/classes for any depending cookbooks

The goal of these cookbooks is to abstract common things into re-usable building blocks. They often
do not include a single recipe because their job is to solely enhance the Chef primitives. It is
also very common for these cookbooks to not include attributes since there's nothing to configure.

Library cookbooks may depend on other library cookbooks or application cookbooks. They never depend
on a Node Cookbook and they never depend on a Wrapper cookbook.

Since the name of an LWRP is derived from the cookbook it is defined in, these cookbooks are named
with that in mind. Pick names that make sense for the way you want LWRPs to appear in recipes.

Library cookbooks are usually public, and you are strongly encouraged to open source your Library
cookbooks.


### Application Cookbooks

These describe a single application or a single piece of software, that share the same name as the
cookbook itself. If the application the cookbook manages contains multiple components then each one
is broken up into it's own recipe and the recipe is named after the component it will install.
Things are broken up in this way so you could install various components spread across a number of
nodes within an environment.

These cookbooks almost always contain a set of attributes which act as the runtime configuration for
the cookbook. These attributes can do something like setting a port number or even describing the
desired state of a service.

Application cookbooks may depend on Library Cookbooks and other Application Cookbooks. They never
depend on Node Cookbooks. They never depend on a Wrapper or Base Cookbook unless they are intended
to be internal to your organization and will never be distributed to the Chef Community Site.

These cookbooks are always named after the application they manage, and are usually name-spaced
with your organization name as a prefix `{organization}_{application_cookbook}`.


### Wrapper Cookbooks

This is the lightest Cookbook out of all the known Cookbook patterns. It does a very simple job of
depending on an Application Cookbook and then exposing a recipe for each recipe found in the
Application Cookbook that it is wrapping.

Wrapper cookbooks depend on Application Cookbooks only. They do not depend on other Wrapper
Cookbooks, Library Cookbooks, or Environment Cookbooks.

These cookbooks follow the naming convention `{organization}_{wrapped_cookbook}` or even sometimes
`{application}_{wrapped_cookbook}`. So the RabbitMQ cookbook for Codio would be called
`codio_rabbitmq`.


### Node Cookbooks

This is the piece that ties the release process of your development cycle together and allows you to
release software that is easy to install and to configure in anyone's infrastructure as long as they
have a Chef Server.

These may encapsulate one or more cookbooks which will be run on a node. They would usually be
private as they are specific to a particular organisation and its nodes. They can be likened to Chef
Roles, but are preferable due to the more flexible nature of a cookbook.

A Node cookbook is the only cookbook that has its Berksfile.lock checked into source control, as it
is used to set the cookbook constraints for the node(s) that this will be applied to. This is
achieved using Chef Environments, where a Node cookbook directly corresponds to a Chef Environment
of the same name. The Berkshelf lock file is converted into the environment's `cookbook_versions`
using the Berkshelf `apply` command.

Node cookbook names are prefixed with `node_`. For example `node_webserver`


### Base Cookbook

All Node Cookbooks require at least one dependency, and that is the Base cookbook. The Base Cookbook
is very similar in nature to a Library Cookbook. It contains several recipes that are common to all
nodes. Examples include configuring NTP and creating system users and SSH access.

The default recipe of your Node cookbooks would be the best place to include your Base cookbook.


## Cookbook Development

Chef Cookbooks must adhere to [Semantic Versioning](http://semver.org/). When developing or testing
changes in a cookbook, you must ensure that the version is set to an odd patch number, for example
`1.0.1`. Patch releases should be even numbers only, for example `1.0.2`, but major and minor
releases can be be both odd and even.

All new releases require that the CHANGELOG.md be updated with the release number and the changes
made in that release.

### Managing Dependencies

[Berkshelf](http://berkshelf.com/) is used to manage Cookbook dependencies in all Cookbooks,
especially Node Cookbooks.

Every Cookbook, no matter what type should alwsy contain a Berksfile with at least the following
content:

```ruby
source "http://berkshelf-api.int.codio.com"

metadata
```

This specifies the Codio Berkshelf API server instead of the usual public Berkshelf API server. The
Codio Berkshelf API server pulls in data from both the Chef Cookbook Community and the Codio Chef
Server.

### Applying Dev Versions

First, don't forget to make sure a dev version is set by setting the patch release to an odd number,
for example `1.0.1`.

Now upload the node cookbook without freezing it:

```bash
$ berks upload --no-freeze
```

Berkshelf will by default, freeze any new cookbook versions that you upload, which prevents further
uploads from overwriting existing versions. This prevents any nasty surprises. By passing the
`--no-freeze` option, the new version will not be frozen, allowing you to continue iterating and
uploading changes to the current version without having to bump the version each time.

#### Node Cookbooks

Because Node cookbooks have the `Berksfile.lock` committed to source control, the development and
release process is a little different.

Follow the steps above first, then continue on below.

Every Node cookbook has a Chef Environment with the same name, and an accompanying development
environment. For example, the `node_fileserver` cookbook has a `node_fileserver` and a
`node_fileserver_dev` Environment. During development, you should ONLY use the dev environment -
that is the environment ending with `_dev`.

Other environments may exist, for example `staging`, which would have a full Chef environment
name of `node_fileserver_dev`. Environments without a suffix, are treated as being a production
environment. For example: `node_fileserver` is the production environment for the FileServer Nodes.

You need to apply the the Node cookbook's version constraints against the development environment.

```bash
$ berks apply ENVIRONMENT_dev
```

Or to the staging environment:

```bash
$ berks apply ENVIRONMENT_staging
```

This will take the `Berksfile.lock` file and apply its cookbook constraints to the environment
you passed.

WARNING: Make sure you apply against the correct environment!.

Run chef on each node of the node environment you applied, and your changes should be run.


## Cookbook Releasing

Releasing a Cookbook is very similar to applying a dev version.

First, don't forget to make sure a release version is set by setting the version accordingly. If it
is a patch release, then sure that you use an even number, for example `1.0.2`.

Now upload the node cookbook:

```bash
$ berks upload
```

#### Node Cookbooks

When releasing a Node cookbook, you need to apply the the Node cookbook's version constraints
against the production environment.

```bash
$ berks apply ENVIRONMENT
```

This will take the `Berksfile.lock` file and apply its cookbook constraints to the environment
you passed. Which in this case, because you passed no suffix, the constraints will be applied
to the production environment.

Now just wait for Chef to run automatically (default every is 2 hours), or run it manually on
each node of the node environment you applied, and your changes should be run.

```bash
sudo chef-client
```


## New Nodes

To create and bootstrap a new Chef Node on EC2, a command similar to this should be run:

```bash
knife ec2 server create -N NODE_NAME -G SECURITY_GROUP_NAME -r "recipe[NODE_COOKBOOK]" -E NODE_ENVIRONMENT --secret-file ~/.chef/codio/encrypted_data_bag_secret -T Product=Codio
```

For more details, please refer to the Git repository README fr the Node Cookbook you are using.
