# JFrog Pipelines Extensions
These extensions are automatically included in the JFrog Pipelines application

## How to add a new extension
1. checkout a branch in the usual format for a bug or feature: "feature-PIPE-1234", "bugfix-PIPE-4321"
2. commit your changes to this branch. You can add the branch locally as an extension source.
3. Once your changes are locally verified, open a PR to master
4. Get your PR approved. QA will test against your branch by adding it as an extension source to their test ENV
5. Once approved, all will be merged to master. From here, create a tag for your extension with the correct format: `<namespace>/<TypeName>@<semver>`. In this case, the namespace should always be `jfrog`
6. Verify in pipe-rc that the new tag has successfully synced, and "release" it via the extensions UI.

Once released in this way, the extension should get packaged with the product as part of the buildplane pipeline.

## How to update an existing extension
1. follow steps 1-5 above
2. Tag your extension with a new version according to semver rules
3. Release your new tag. it should get packaged alongside the original tag as part of buildplane.
