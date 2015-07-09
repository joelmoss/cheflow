## Cookbooks

Each and every cookbook is either a Node or a Non-Node cookbook, and every cookbook should reside in
its very own Git repository. Additionally, there is a Base cookbook that must be the very first
dependency of each Node cookbook.


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

Node cookbooks should never be a dependency for any other cookbook.

Node cookbook names are prefixed with `node_`. For example `node_webserver`


### Non-Node Cookbook

Anything that is not specific to a node, and is required to be reusable, should appear in a Non-Node
cookbook.

Non-Node cookbooks should be consumed and depended on by one or more Node cookbooks, and should
never be used directly. Easy peasy!


### Base Cookbook

All Node Cookbooks require at least one dependency, and that is the Base cookbook.

This is the most basic building block of Cookbooks. These types of cookbooks are reusable and are
mixed into other Node cookbooks to enhance them by:

  - Adding LWRPs that abstract common functionality
  - Including Libraries that add Ruby modules/classes for any depending cookbooks

The goal of these cookbooks is to abstract common things into re-usable building blocks. It contains
several recipes that are common to all nodes. Examples include configuring NTP, creating system
users and SSH access.

The default recipe of your Node cookbooks should usually begin with your Base cookbook being
included first.



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

Every Cookbook, no matter what type should always containa a Berksfile with at least the following
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
