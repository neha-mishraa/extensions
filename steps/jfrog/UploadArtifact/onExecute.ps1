$ErrorActionPrefence = "Stop"

Function upload_artifact() {
  $integrationName = get_integration_name -type "Artifactory"

  if ([string]::IsNullOrEmpty("$integrationName")) {
    Write-Output "Error: No Artifactory integration found"
    throw "Error: No Artifactory integration found"
  }

  execute_command "$jfrog_cli_path rt use $integrationName"

  execute_command "New-Item -Path `"$step_tmp_dir/ArtifactUpload`" -ItemType Directory -Force"
  execute_command "Push-Location `"$step_tmp_dir/ArtifactUpload`""

  $fileSpecName = get_resource_name -type FileSpec -operation IN
  if (-not ([string]::IsNullOrEmpty("$fileSpecName"))) {
    $resourcePath = find_resource_variable "$fileSpecName" resourcePath
    execute_command "Copy-Item -Path `"${resourcePath}\*`" -Recurse"
  }

  $remoteFileName = get_resource_name -type RemoteFile -operation IN
  if (-not ([string]::IsNullOrEmpty("$remoteFileName"))) {
    $resourcePath = find_resource_variable "$remoteFileName" resourcePath
    execute_command "Copy-Item -Path `"${resourcePath}\*`" -Recurse"
  }

  $gitRepoName = get_resource_name -type GitRepo -operation IN
  if (-not ([string]::IsNullOrEmpty("$gitRepoName"))) {
    $resourcePath = find_resource_variable "$gitRepoName" resourcePath
    execute_command "Copy-Item -Path `"${resourcePath}\*`" -Recurse"
  }

  $sourcePath = find_step_configuration_value sourcePath
  $targetPath = find_step_configuration_value targetPath
  $properties = find_step_configuration_value properties
  $regExp = find_step_configuration_value regExp
  $flat = find_step_configuration_value flat
  $module = find_step_configuration_value module
  $deb = find_step_configuration_value deb
  $recursive = find_step_configuration_value recursive
  $dryRun = find_step_configuration_value dryRun
  $symlinks = find_step_configuration_value symlinks
  $explode = find_step_configuration_value explode
  $includeDirs = find_step_configuration_value includeDirs
  $exclusions = find_step_configuration_value exclusions
  $syncDeletes = find_step_configuration_value syncDeletes

  if ([string]::IsNullOrEmpty("$sourcePath")) {
    if ( "$regExp" -eq "true" ) {
      $sourcePath = ".*"
    } else {
      $sourcePath = "*"
    }
  }

  if ([string]::IsNullOrEmpty("$targetPath")) {
    Write-Output "Error: No targetPath found"
    throw "Error: No targetPath found"
  }

  $parameters = ""

  if (-not [string]::IsNullOrEmpty("$module")) {
    $parameters += " --module=`"${module}`" "
  }

  $uploadProperties = ""
  if (-not [string]::IsNullOrEmpty("$properties")) {
    $uploadProperties = "${properties};"
  }
  $uploadProperties += "pipelines_step_name=${step_name};pipelines_run_number=${run_number};pipelines_step_id=${step_id};pipelines_pipeline_name=${pipeline_name};pipelines_step_url=${step_url};pipelines_step_type=${step_type};pipelines_step_platform=${step_platform}"
  $parameters += " --props=`"${uploadProperties}`" "


  if (-not [string]::IsNullOrEmpty("$deb")) {
    $parameters += " --deb=`"$deb`""
  }

  if (-not [string]::IsNullOrEmpty("$flat")) {
    $parameters += " --flat=${flat}"
  }

  if (-not [string]::IsNullOrEmpty("$recursive")) {
    $parameters += " --recursive=${recursive}"
  }

  if (-not [string]::IsNullOrEmpty("$regExp")) {
    $parameters += " --regexp=${regexp}"
  }

  if (-not [string]::IsNullOrEmpty("$dryRun")) {
    $parameters += " --dry-run=${dryRun}"
  }

  if (-not [string]::IsNullOrEmpty("$symlinks")) {
    $parameters += " --symlinks=${symlinks}"
  }

  if (-not [string]::IsNullOrEmpty("$explode")) {
    $parameters += " --explode=${explode}"
  }

  if (-not [string]::IsNullOrEmpty("$includeDirs")) {
    $parameters += " --include-dirs=${includeDirs}"
  }

  if (-not [string]::IsNullOrEmpty("$exclusions")) {
    $parameters += " --exclusions=`"${exclusions}`""
  }

  if (-not [string]::IsNullOrEmpty("$syncDeletes")) {
    $parameters += " --sync-deletes=`"${syncDeletes}`""
  }

  execute_command "$jfrog_cli_path rt upload `"${sourcePath}`" `"${targetPath}`" $parameters --insecure-tls=$no_verify_ssl --fail-no-op=true --detailed-summary=true"

  $outputFileSpecResourceName = get_resource_name -type FileSpec -operation OUT

  if ( "$outputFileSpecResourceName" -ne "" ) {
    execute_command "write_output ${outputFileSpecResourceName} pattern=`"${targetPath}`" props=`"${uploadProperties}`""
  }

  $autoPublishBuildInfo = find_step_configuration_value autoPublishBuildInfo
  $forceXrayScan = find_step_configuration_value forceXrayScan
  $failOnScan = find_step_configuration_value failOnScan

  execute_command "add_run_variables buildStepName=${step_name}"
  execute_command "add_run_variables ${step_name}_buildNumber=$JFROG_CLI_BUILD_NUMBER"
  execute_command "add_run_variables ${step_name}_buildName=$JFROG_CLI_BUILD_NAME"

  execute_command "$jfrog_cli_path rt build-collect-env $JFROG_CLI_BUILD_NAME $JFROG_CLI_BUILD_NUMBER"


  if ( "$autoPublishBuildInfo" -eq "true" ) {
    if ( -not ((Test-Path env:JFROG_CLI_ENV_EXCLUDE) -or (Test-Path variable:global:JFROG_CLI_ENV_EXCLUDE))) {
      execute_command 'Set-Item "env:JFROG_CLI_ENV_EXCLUDE" "buildinfo.env.res_*;buildinfo.env.int_*;buildinfo.env.current_*;*password*;*secret*;*key*;*token*"'
      execute_command 'New-Variable -Name "JFROG_CLI_ENV_EXCLUDE" -Scope Global -Value "buildinfo.env.res_*;buildinfo.env.int_*;buildinfo.env.current_*;*password*;*secret*;*key*;*token*"'
    }

    execute_command "retry_command $jfrog_cli_path rt build-publish --insecure-tls=$no_verify_ssl $JFROG_CLI_BUILD_NAME $JFROG_CLI_BUILD_NUMBER"

    $outputBuildInfoResourceName = get_resource_name -type BuildInfo -operation OUT

    if ( "$outputBuildInfoResourceName" -ne "" ) {
      execute_command "write_output $outputBuildInfoResourceName buildName=${JFROG_CLI_BUILD_NAME} buildNumber=${JFROG_CLI_BUILD_NUMBER}"
    }
  }

  if ( "$forceXrayScan" -eq "true" ) {
    if ( "$failOnScan" -eq "") {
      $failOnScan = "true"
    }
    execute_command "$jfrog_cli_path rt build-scan --insecure-tls=${no_verify_ssl} --fail=${failOnScan} $buildName $JFROG_CLI_BUILD_NUMBER"
  }

  $jfrogPath = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "\jfrog\."
  execute_command "add_run_files $jfrogPath jfrog"

  execute_command "Pop-Location"
}

upload_artifact
