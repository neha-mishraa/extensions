# UploadArtifact (1.0.0)
This step can be used to upload files to Artifactory. FileSpec, RemoteFile, and GitRepo inputs are supported (up to one of each), and by default everything in those resources will be uploaded. Optional outputs are BuildInfo (with `autoPublishBuildInfo` set to `true`) and FileSpec resources. See the JFrog Artifactory CLI rt upload command for more information about the possible filters.

### YML
```
- name: myUploadArtifactStep
  type: UploadArtifact
  configuration:
    integrations:
      - name:             <Artifactory integration>  # required
    inputResources:
      - name:             <FileSpec resource>
      - name:             <RemoteFile resource>
      - name:             <GitRepo resource>
    outputResources:
      - name:             <FileSpec resource> # The pattern will be updated with the targetPath and the properties with the properties of the uploaded Artifact.
      - name:             <BuildInfo resource> # Updated if autoPublishBuildInfo is true.
    autoPublishBuildInfo: <Boolean> # If true, Build Info for the step will be published.
    forceXrayScan:        <Boolean> # If true, an Xray Scan will be triggered for the step.
    failOnScan:           <Boolean> # If a scan failure should cause a step failure, default true.
    sourcePath:           <string> # Files to upload. Default *.
    targetPath:           <string> # Where to upload the files, including repository name. Required.
    properties:           <string> # Semi-colon separated properties for the uploaded Artifact, e.g. "myFirstProperty=one;mySecondProperty=two". pipelines_step_name, pipelines_run_number, pipelines_step_id, pipelines_pipeline_name, pipelines_step_url, pipelines_step_type, and pipelines_step_platform will also be added.
    regExp:               <Boolean> # If true, sourcePath uses regular expressions instead of wildcards. Expressions must be in parentheses.
    flat:                 <Boolean> # If true, the uploaded files are flattened removing the directory structure.
    module:               <string> # A module name for the Build Info.
    deb:                  <string> # A distribution/component/architecture for Debian packages. If a component includes a / it must be double-escaped, e.g. distribution/my\\\/component/architecture for a my/component component.
    recursive:            <Boolean> # If false, do not upload any matches in sub-directories.
    dryRun:               <Boolean> # If true, nothing is uploaded.
    symlinks:             <Boolean> # If true, symlinks are uploaded.
    explode:              <Boolean> # If true and the uploaded Artifact is an archive, the archive is expanded.
    exclusions:           <string> # Semi-colon separated patterns to exclude.
    includeDirs:          <Boolean> # If true, empty directories matching the criteria are uploaded.
    syncDeletes:          <string> # A path under which to delete any existing files in Artifactory.
```
