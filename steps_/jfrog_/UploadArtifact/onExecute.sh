#!/bin/bash -e

upload_artifact() {
  local integrationName=$(get_integration_name --type "Artifactory")

  if [ -z "$integrationName" ]; then
    execute_command "echo 'No Artifactory integration found'"
    return 1
  fi

  execute_command "\$jfrog_cli_path rt use $integrationName"

  execute_command "mkdir -p \"\$step_tmp_dir/ArtifactUpload\""
  execute_command "pushd \"\$step_tmp_dir/ArtifactUpload\""

  local fileSpecName=$(get_resource_name --type FileSpec --operation IN)
  if [ ! -z "$fileSpecName" ]; then
    local resourcePath=$(find_resource_variable "$fileSpecName" resourcePath)
    execute_command "cp -r ${resourcePath}/* ."
  fi

  local remoteFileName=$(get_resource_name --type RemoteFile --operation IN)
  if [ ! -z "$remoteFileName" ]; then
    local resourcePath=$(find_resource_variable "$remoteFileName" resourcePath)
    execute_command "cp -r ${resourcePath}/* ."
  fi

  local gitRepoName=$(get_resource_name --type GitRepo --operation IN)
  if [ ! -z "$gitRepoName" ]; then
    local resourcePath=$(find_resource_variable "$gitRepoName" resourcePath)
    execute_command "cp -r ${resourcePath}/* ."
  fi

  local sourcePath=$(find_step_configuration_value sourcePath)
  local targetPath=$(find_step_configuration_value targetPath)
  local properties=$(find_step_configuration_value properties)
  local regExp=$(find_step_configuration_value regExp)
  local flat=$(find_step_configuration_value flat)
  local module=$(find_step_configuration_value module)
  local deb="$(find_step_configuration_value deb)"
  local recursive=$(find_step_configuration_value recursive)
  local dryRun=$(find_step_configuration_value dryRun)
  local symlinks=$(find_step_configuration_value symlinks)
  local explode=$(find_step_configuration_value explode)
  local includeDirs=$(find_step_configuration_value includeDirs)
  local exclusions=$(find_step_configuration_value exclusions)
  local syncDeletes=$(find_step_configuration_value syncDeletes)

  if [ -z "$sourcePath" ]; then
    if [ "$regExp" == "true" ]; then
      sourcePath=".*"
    else
      sourcePath="*"
    fi
  fi
  if [ -z "$targetPath" ]; then
    execute_command "echo 'No targetPath found'"
    return 1
  fi

  local parameters=""

  if [ ! -z "$module" ]; then
    parameters+=" --module=${module}"
  fi

  local uploadProperties=""
  if [ ! -z "$properties" ]; then
    uploadProperties="${properties};"
  fi
  uploadProperties+="pipelines_step_name=${step_name};pipelines_run_number=${run_number};pipelines_step_id=${step_id};pipelines_pipeline_name=${pipeline_name};pipelines_step_url=${step_url};pipelines_step_type=${step_type};pipelines_step_platform=${step_platform}"
  parameters+=" --props='${uploadProperties}'"

  if [ ! -z "$deb" ]; then
    parameters+=" --deb='${deb}'"
  fi

  if [ ! -z "$flat" ]; then
    parameters+=" --flat=${flat}"
  fi

  if [ ! -z "$recursive" ]; then
    parameters+=" --recursive=${recursive}"
  fi

  if [ ! -z "$regExp" ]; then
    parameters+=" --regexp=${regExp}"
  fi

  if [ ! -z "$dryRun" ]; then
    parameters+=" --dry-run=${dryRun}"
  fi

  if [ ! -z "$symlinks" ]; then
    parameters+=" --symlinks=${symlinks}"
  fi

  if [ ! -z "$explode" ]; then
    parameters+=" --explode=${explode}"
  fi

  if [ ! -z "$includeDirs" ]; then
    parameters+=" --include-dirs=${includeDirs}"
  fi

  if [ ! -z "$exclusions" ]; then
    parameters+=" --exclusions='${exclusions}'"
  fi

  if [ ! -z "$syncDeletes" ]; then
    parameters+=" --sync-deletes='${syncDeletes}'"
  fi

  execute_command "\$jfrog_cli_path rt upload \"$sourcePath\" \"$targetPath\" $parameters --insecure-tls=$no_verify_ssl --fail-no-op=true --detailed-summary=true"

  local outputFileSpecResourceName=$(get_resource_name --type FileSpec --operation OUT)

  if [ ! -z "$outputFileSpecResourceName" ]; then
    execute_command "write_output $outputFileSpecResourceName pattern='$targetPath' props='$uploadProperties'"
  fi

  local autoPublishBuildInfo=$(find_step_configuration_value autoPublishBuildInfo)
  local forceXrayScan=$(find_step_configuration_value forceXrayScan)
  local failOnScan=$(find_step_configuration_value failOnScan)

  execute_command "add_run_variables buildStepName=${step_name}"
  execute_command "add_run_variables ${step_name}_buildNumber=$JFROG_CLI_BUILD_NUMBER"
  execute_command "add_run_variables ${step_name}_buildName=$JFROG_CLI_BUILD_NAME"

  execute_command "\$jfrog_cli_path rt build-collect-env $JFROG_CLI_BUILD_NAME $JFROG_CLI_BUILD_NUMBER"

  if [ "$autoPublishBuildInfo" == "true" ]; then
    if [ -z "$JFROG_CLI_ENV_EXCLUDE" ]; then
      execute_command 'export JFROG_CLI_ENV_EXCLUDE="buildinfo.env.res_*;buildinfo.env.int_*;buildinfo.env.current_*;*password*;*secret*;*key*;*token*"'
    fi
    execute_command "retry_command \$jfrog_cli_path rt build-publish --insecure-tls=$no_verify_ssl $JFROG_CLI_BUILD_NAME $JFROG_CLI_BUILD_NUMBER"

    local outputBuildInfoResourceName=$(get_resource_name --type BuildInfo --operation OUT)

    if [ ! -z "$outputBuildInfoResourceName" ]; then
      execute_command "write_output $outputBuildInfoResourceName buildName=$JFROG_CLI_BUILD_NAME buildNumber=$JFROG_CLI_BUILD_NUMBER"
    fi
  fi

  if [ "$forceXrayScan" == "true" ]; then
    if [ -z "$failOnScan" ]; then
      failOnScan="true"
    fi
    execute_command "\$jfrog_cli_path rt build-scan --insecure-tls=$no_verify_ssl --fail=$failOnScan $JFROG_CLI_BUILD_NAME $JFROG_CLI_BUILD_NUMBER"
  fi

  execute_command "add_run_files /tmp/jfrog/. jfrog"

  execute_command "popd"
}

upload_artifact
