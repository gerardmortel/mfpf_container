#   Licensed Materials - Property of IBM 
#   5725-I43 (C) Copyright IBM Corp. 2011, 2015. All Rights Reserved.
#   US Government Users Restricted Rights - Use, duplication or
#   disclosure restricted by GSA ADP Schedule Contract with IBM Corp.  
   
#!/usr/bin/bash

usage() 
{
   echo 
   echo " Preparing the MobileFirst Platform Foundation Server Image "
   echo " ------------------------------------------------------------ "
   echo " This script loads, customizes, tags, and pushes the MobileFirst Server image"
   echo " to the IBM Containers service on Bluemix."
   echo " Prerequisite: The prepareserverdbs.sh script is run before running this script."
   echo
   echo " Silent Execution (arguments provided as command-line arguments): "
   echo "   USAGE: prepareserver.sh <command-line arguments> "
   echo "   command-line arguments: "
   echo "     -t | --tag SERVER_IMAGE_TAG   Name to be used for the customized MobileFirst Server image"
   echo "                                     Format: registryUrl/namespace/name:tag"
   echo "     -l | --loc PROJECT_LOC        (Optional) The location of the MobileFirst project"
   echo "                                     Multiple project locations can be delimited by commas."
   echo
   echo " Silent Execution (arguments loaded from file): "
   echo "   USAGE: prepareserver.sh <path to the file from which arguments are read> "
   echo "          See args/prepareserver.properties for the list of arguments."
   echo 
   echo " Interactive Execution: "
   echo "   USAGE: prepareserver.sh"
   echo
   exit 1
}

readParams()
{
    # Read the name for the MobileFirst Server image
    #----------------------------------------------
    INPUT_MSG="Specify the name for the MobileFirst Server image. Should be of form registryUrl/repositoryNamespace/imagename (mandatory) : "
    ERROR_MSG="Name for MobileFirst Server image cannot be empty. Specify the name for the image. (mandatory) : "
    SERVER_IMAGE_TAG=$(fnReadInput "$INPUT_MSG" "$ERROR_MSG")
    
    read -p "Specify the comma-separated paths of the MobileFirst projects to be added to this image. If nothing is specified, only the projects copied to the usr/projects directory are added. (optional) : " PROJECT_LOC
   
}

validateParams() 
{
		if [ -z "$SERVER_IMAGE_TAG" ]
		then
	    	echo Server Image Name is empty. A mandatory argument must be specified. Exiting...
			exit 0
		fi
}

verifyBuildVersionPresent(){
   echo "----------- Verify Build Version Present ----------------"
   echo
   cd $1
   echo $2
   pwd
    if [ -e worklight.properties ]
    then
      echo "worklight.properties file exists in $1"
      if ! grep -q "project.build.version=" worklight.properties
      then
      echo "Build Version not present in worklight.properties"
      echo "Copying build version from the war file present at $2"
     #  tail -n2 $2/worklight.properties
     # echo $(tail -n1 $2/worklight.properties) >> worklight.properties
     echo $(grep "project.build.version=" $2/worklight.properties) >> worklight.properties
      fi
    else 
      echo "worklight.properties file does not exist in $1"
    fi 
     echo
     echo "------------------------------------------------------"
     echo
}

repackageWarFile(){
   binDir=${1%/*}
   projectDir=${binDir%/*}
   mkdir -p $projectDir/tmp
   cd $projectDir/tmp
   jar -xf $1
   rm $1
   if [ -d "$projectDir/server/conf" ] && [ "$(ls -A $projectDir/server/conf)" ]
   then
      verifyBuildVersionPresent $projectDir/server/conf $projectDir/tmp/WEB-INF/classes/conf/
      cd $projectDir/tmp
      cp $projectDir/server/conf/* $projectDir/tmp/WEB-INF/classes/conf/
   fi
   if [ -d "$projectDir/server/lib" ] && [ "$(ls -A $projectDir/server/lib)" ]
   then
      cp $projectDir/server/lib/* $projectDir/tmp/WEB-INF/lib/
   fi   
   jar -cf $1 *
   cd $projectDir
   rm -rf $projectDir/tmp
}

copyProjects(){
   IFS=","
   for v in $PROJECT_LOC
   do
      projName=${v##*"/"}
      if [ -d "$v" ] && [ -e "$v/bin/$projName.war" ]
         then
         echo "$v is a valid project path. Copying project artifacts."

         mkdir -p  ../usr/projects/$projName/bin
         cp -f $v/bin/$projName.war ../usr/projects/$projName/bin/
         adapter_files=$(find $v/bin/ -maxdepth 1 -name "*.adapter")
         if [ ! -z $adapter_files ]
         then
            echo "copying adapters " $adapter_files
            cp -f $v/bin/*.adapter ../usr/projects/$projName/bin/
         fi

         wlapp_files=$(find $v/bin/ -maxdepth 1 -name "*.wlapp")
         if [ ! -z $wlapp_files ]
         then
            echo "copying applications " $wlapp_files
            cp -f $v/bin/*.wlapp ../usr/projects/$projName/bin/
         fi
      else
         echo "$v is not a valid project path or it does not contain a runtime .war file in the $v/bin/ directory. Checking for .war files in the $v directory. Each .war file represents a runtime."
         war_files=$(find $v/ -maxdepth 1 -name "*.war")
         if [ ! -z $war_files ]
         then
            for f in $v/*.war
            do
               projName=${f##*"/"}
               projName=${projName::$((${#projName}-4))}
               mkdir -p  ../usr/projects/$projName/bin
               cp -f $f ../usr/projects/$projName/bin/
            done
         else
            echo "Directory $v does not contain any runtime .war file."
            exit 1
         fi
      fi
   done
}

buildProjects()
{
   currentDir=`pwd`
   for dir in ../usr/projects/*; do      
      projectDir=$dir
      projectName=${dir##*/}      
      for file in $projectDir/bin/*; do                 
         if [[ ${file##*.} == war ]]
            then             
               warFilePath=$currentDir/$file
               repackageWarFile $warFilePath
               cd $currentDir
               break
         fi
      done
   done
}

copyWARtoRootFolder()
{
	for dir in ../usr/projects/*; do
		projectDir=$dir
		projectName=${dir##*/}
		
		if [[ -f $projectDir/bin/$projectName.war ]]
		then
			if [[ -f ../usr/projects/$projectName.war ]] 
			then
			    echo "Warning. Project war with same name already exists in usr/projects folder. Ignoring the file from folder : " $projectDir/bin
		    else
         		mv -f $projectDir/bin/$projectName.war ../usr/projects
		    fi 
		fi
	done
}

migrateProjects()
{
   #### Migrate the project WAR files
   # check if user has overridden JAVA_HOME . else set to standard location
   if [ -z "$JAVA_HOME" ]
   then
      # export JAVA_HOME = "/usr/java"
      echo "JAVA_HOME not set. Please set JAVA_HOME for MFP migration to continue"
      exit 1
   else
      echo "JAVA_HOME:" $JAVA_HOME
   fi

   for war in ../usr/projects/*.war; do
      echo "******* Migrating:" $war "********"
	  ../../mfpf-libs/apache-ant-1.9.4/bin/ant -f migrate.xml -Dwarfile=$war
   done
   
}

clean_up() {
	# Perform clean up before exiting
	cd "${absoluteScriptDir}"
        
    if [ -d ../dependencies ]
    then
        mv ../dependencies ../../dependencies
    fi
    if [ -d ../mfpf-libs ]
    then
        mv ../mfpf-libs ../../mfpf-libs
    fi

    if [ -d ../licenses ]
    then 
        rm -rf ../licenses
    fi
    
    currentDir=`pwd`
    for dir in ../usr/projects/*; do
    	projectDir=$dir
    	projectName=${dir##*/}
    	for file in $projectDir/bin/*; do
    		if [[ ${file##*.} == war ]]
    		then
    			if [[ -d ${projectDir}/tmp  && ! -z ${projectDir} ]]
    			then
    				rm -rf ${projectDir}/tmp
    			fi
    		    break
    		fi
    	done
    done
    
    for war in ../usr/projects/*.war; do
  	  warName=${war##*/}
      projectName=${warName%.*}
  	  if [[ -d ../usr/projects/$projectName/bin ]] && [[ ! -f ../usr/projects/$projectName/bin/$projectName.war ]] 
	  then
  	      mv -f $war ../usr/projects/$projectName/bin
	  fi
    done
}

cd "$( dirname "$0" )"

source ./common.sh


if [ $# == 0 ]
then
   readParams
elif [ "$#" -eq 1 -a -f "$1" ]
then
   source "$1"
elif [ "$1" = "-h" -o "$1" = "--help" ]
then
   usage
else
   while [ $# -gt 0 ]; do
      case "$1" in
         -t | --tag)
            SERVER_IMAGE_TAG="$2";
            shift
            ;;
         -l | --loc)
            PROJECT_LOC="$2";
            shift
            ;;
         *)
            usage
            ;;
      esac
      shift
   done
fi

validateParams

#main

set -e
trap clean_up 0 1 2 3 15

scriptDir=`dirname $0`
absoluteScriptDir=`pwd`/${scriptDir}/


echo "Arguments : "
echo "----------- "
echo 
echo "SERVER_IMAGE_NAME : " $SERVER_IMAGE_TAG
echo "PROJECT_LOC : " $PROJECT_LOC
echo

copyProjects
buildProjects
copyWARtoRootFolder
migrateProjects

mv ../../dependencies ../dependencies
mv ../../mfpf-libs ../mfpf-libs
cp -rf ../../licenses ../licenses

echo "Building the MobileFirst Server image : " $SERVER_IMAGE_TAG
docker build -t $SERVER_IMAGE_TAG ../

mv ../dependencies ../../dependencies
mv ../mfpf-libs ../../mfpf-libs
rm -rf ../licenses

echo "Pushing the MobileFirst Server image to the IBM Containers registry.."
docker push $SERVER_IMAGE_TAG