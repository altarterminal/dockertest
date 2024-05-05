#!/bin/sh
set -eu

######################################################################
# user setting
######################################################################

rurl='https://github.com/altarterminal/jenkinstest'
bname='main'
desc='this job has been auto generated'

######################################################################
# setting
######################################################################

print_usage_and_exit () {
  cat <<-USAGE 1>&2
	Usage   : ${0##*/}
	Options :

	add a jenkins job
	cmd example: create-job auto-job

	curret setting:
	repository url: "$rurl"
	branch name: "$bname"
	description: "$desc"
	USAGE
  exit 1
}

######################################################################
# parameter
######################################################################

opr=''

i=1
for arg in ${1+"$@"}
do
  case "$arg" in
    -h|--help|--version) print_usage_and_exit ;;
   *)
      if [ $i -eq $# ] && [ -z "$opr" ]; then
        opr=$arg
      else
        echo "${0##*/}: invalid args" 1>&2
        exit 11
      fi
      ;;
  esac

  i=$((i + 1))
done

######################################################################
# main routine
######################################################################

cat <<'EOF'                                                          |
<flow-definition plugin="workflow-job@1289.vd1c337fd5354">
  <actions>
    <org.jenkinsci.plugins.pipeline.modeldefinition.actions.DeclarativeJobAction plugin="pipeline-model-definition@2.2125.vddb_a_44a_d605e"/>
    <org.jenkinsci.plugins.pipeline.modeldefinition.actions.DeclarativeJobPropertyTrackerAction plugin="pipeline-model-definition@2.2125.vddb_a_44a_d605e">
      <jobProperties/>
      <triggers/>
      <parameters/>
      <options/>
    </org.jenkinsci.plugins.pipeline.modeldefinition.actions.DeclarativeJobPropertyTrackerAction>
  </actions>
  <description><<desc>></description>
  <keepDependencies>false</keepDependencies>
  <properties/>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition" plugin="workflow-cps@3653.v07ea_433c90b_4">
    <scm class="hudson.plugins.git.GitSCM" plugin="git@5.0.0">
      <configVersion>2</configVersion>
      <userRemoteConfigs>
        <hudson.plugins.git.UserRemoteConfig>
          <url><<rurl>></url>
        </hudson.plugins.git.UserRemoteConfig>
      </userRemoteConfigs>
      <branches>
        <hudson.plugins.git.BranchSpec>
          <name>*/<<bname>></name>
        </hudson.plugins.git.BranchSpec>
      </branches>
      <doGenerateSubmoduleConfigurations>false</doGenerateSubmoduleConfigurations>
      <submoduleCfg class="empty-list"/>
      <extensions/>
    </scm>
    <scriptPath>Jenkinsfile</scriptPath>
    <lightweight>true</lightweight>
  </definition>
  <triggers/>
  <disabled>false</disabled>
</flow-definition>
EOF

sed 's!<<rurl>>!'"${rurl}"'!'                                             |
sed 's!<<bname>>!'"${bname}"'!'                                           |
sed 's!<<desc>>!'"${desc}"'!'                                             |

cat
