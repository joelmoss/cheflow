## 0.3.0 (UNRELEASED)

- [Improvement] Don't return an environment that has no versions of the cookbook in it.
- [Feature] Added `bump` command which will bump the version of the current cookbook.
- [Feature] Added `upload` command which will upload the current cookbook.
- [Feature] Added straight up copies of the `outdated` and `update` Berkshelf commands.
- [Feature] Added `apply` command to apply locked versions to the given environment.

## 0.2.0

- [Improvement] Only showing the 15 most recent version in the info command.
- [Improvement] Showing environments that non-node cookbooks are included within.
- [Fix] using correct environment.

## 0.1.0

Initial release supporting only the `info` command.