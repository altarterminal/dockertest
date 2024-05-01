#!/bin/sh
set -eu

######################################################################
# setting
######################################################################

print_usage_and_exit () {
  cat <<-USAGE 1>&2
	Usage   : ${0##*/} -r<repository> 
	Options : -b<branch-name> -c<credential-ID> -d<description>

	add a jenkins job
	cmd example: create-job auto-job

	-r: specify the repository url
	-b: specify the branch name (default: main)
	-c: specify the credential ID (default: auto-credential-id)
	-d: specify the description (default: this job has been auto generated)
	USAGE
  exit 1
}

######################################################################
# parameter
######################################################################

opr=''
opt_r=''
opt_b='main'
opt_c='auto-credential-id'
opt_d='this job has been auto generated'

i=1
for arg in ${1+"$@"}
do
  case "$arg" in
    -h|--help|--version) print_usage_and_exit ;;
    -r*)                 opt_r=${arg#-r}      ;;
    -b*)                 opt_b=${arg#-b}      ;;
    -c*)                 opt_c=${arg#-c}      ;;
    -d*)                 opt_d=${arg#-d}      ;;
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

if [ -z "$opt_r" ]; then
  echo "${0##*/}: repository must be specified" 1>&2
  exit 21
fi

if [ -z "$opt_b" ]; then
  echo "${0##*/}: branch name must be specified" 1>&2
  exit 31
fi

if [ -z "$opt_c" ]; then
  echo "${0##*/}: credential ID must be specified" 1>&2
  exit 31
fi

rname=${opt_r}
bname=${opt_b}
cid=${opt_c}
desc=${opt_d}

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
          <url><<rname>></url>
          <credentialsId><<cid>></credentialsId>
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

sed 's!<<rname>>!'"${rname}"'!'                                           |
sed 's!<<bname>>!'"${bname}"'!'                                           |
sed 's!<<cid>>!'"${cid}"'!'                                               |
sed 's!<<desc>>!'"${desc}"'!'                                             |

cat
