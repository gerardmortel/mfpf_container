#   Licensed Materials - Property of IBM 
#   5725-I43 (C) Copyright IBM Corp. 2011, 2015. All Rights Reserved.
#   US Government Users Restricted Rights - Use, duplication or
#   disclosure restricted by GSA ADP Schedule Contract with IBM Corp.  
   
#!/usr/bin/bash

usage() 
{
   echo 
   echo " Configuring the database service on Bluemix to use with MobileFirst Server image "
   echo " -------------------------------------------------------------------------------- "
   echo " Use this script to configure MobileFirst Server databases (administration and runtime)"
   echo " You must run this script once for administration database and then individually for each runtime."
   echo
   echo " Silent Execution (arguments provided as command line arguments):"
   echo "   USAGE: prepareserverdbs.sh <command line arguments> "
   echo "   command-line arguments: "
   echo "     -n | --name DB_SRV_NAME           Bluemix database service instance name"
   echo "     -an | --appname APP_NAME          Bluemix application name"
   echo "     -r | --runtime RUNTIME_NAME       (Optional) MobileFirst runtime name (required for configuring runtime databases only)"
   echo "     -sn | --schema SCHEMA_NAME        (Optional) Database schema name (defaults to WLADMIN for administration databases "
   echo "                                         or the runtime name for runtime databases)"
   echo "                                         Note: Schema creation is applicable only to sqldb service. "
   echo "                                               The option is ignored if sqldb_free plan is chosen - The default schema is used."
   echo 
   echo " Silent Execution (arguments loaded from file):"
   echo "   USAGE: prepareserverdbs.sh <path to the file from which arguments are read>"
   echo "          See args/prepareserverdbs.properties for the list of arguments."
   echo 
   echo " Interactive Execution: "
   echo "   USAGE: prepareserverdbs.sh"
   echo
   exit 1
}

readParams()
{
    
        # Read the IBM Bluemix Database Service Name.
        #--------------------------------------------
    	INPUT_MSG="Specify the name of your Bluemix database service. (mandatory) : "
        ERROR_MSG="Bluemix Database Service Name cannot be empty. Specify the name of your Bluemix database service. (mandatory) : "
        DB_SRV_NAME=$(fnReadInput "$INPUT_MSG" "$ERROR_MSG")

        # Read the IBM Bluemix Application Name
        #--------------------------------------
        INPUT_MSG="Specify the name of your Bluemix application (mandatory) : "
        ERROR_MSG="IBM Bluemix Application Name cannot be empty. Specify the name of your Bluemix application (mandatory) : "
        APP_NAME=$(fnReadInput "$INPUT_MSG" "$ERROR_MSG")
 
        # Read the Runtime / Project Name
        #--------------------------------
        read -p "Specify your runtime name or project name (If not specified, the script will perform the configuration of administration database) (optional) : " RUNTIME_NAME
 
        # Read the Database Schema Name 
        #------------------------------
        read -p "Specify the name of the database schema (defaults to WLADMIN for administration database or the runtime name for runtime databases) (optional) : " SCHEMA_NAME

}

validateParams() 
{
	if [ -z "$BLUEMIX_API_URL" ]
	then
		BLUEMIX_API_URL=https://api.ng.bluemix.net
	fi

	if [ -z "$DB_SRV_NAME" ]
	then
    	echo IBM Bluemix Database Service Name field is empty. A mandatory argument must be specified. Exiting...
		exit 0
	fi
	
	if [ -z "$APP_NAME" ]
	then
   		echo IBM Bluemix App Name field is empty. A mandatory argument must be specified. Exiting...
		exit 0
	fi
	
   if [ -z "$RUNTIME_NAME" ]
   then
   	 if [ -z "$SCHEMA_NAME" ]
   	 then
   	 	SCHEMA_NAME=WLADMIN
   	 fi
   else
   	 if [ -z "$SCHEMA_NAME" ]
   	 then
   	 	SCHEMA_NAME=$RUNTIME_NAME
   	 fi
   fi
}

cd "$( dirname "$0" )"

source ./common.sh

# check if user has overridden JAVA_HOME . 
if [ -z "$JAVA_HOME" ]
then
   echo "JAVA_HOME is not set. Please set JAVA_HOME and retry."
   exit 1
fi

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
         -a | --api)
            BLUEMIX_API_URL="$2";
            shift
            ;;
         -u | --user)
            BLUEMIX_USER="$2";
            shift
            ;;
         -p | --password)
            BLUEMIX_PASSWORD="$2";
            shift
            ;;
         -o | --org)
            BLUEMIX_ORG="$2";
            shift
            ;;
         -s | --space)
            BLUEMIX_SPACE="$2";
            shift
            ;;
         -n | --name)
            DB_SRV_NAME="$2";
            shift
            ;;
         -an | --appname)
            APP_NAME="$2";
            shift
            ;;
         -r | --runtime)
            RUNTIME_NAME="$2";
            shift
            ;;
         -sn | --schema)
            SCHEMA_NAME="$2";
            shift
            ;;
         *)
            usage
            ;;
      esac
      shift
   done
fi

trap - SIGINT

validateParams

#main

echo "Arguments : "
echo "----------- "
echo
echo "DB_SRV_NAME : " $DB_SRV_NAME
echo "APP_NAME : " $APP_NAME
echo "RUNTIME_NAME : " $RUNTIME_NAME
echo "SCHEMA_NAME : " $SCHEMA_NAME
echo
echo "JAVA_HOME:" $JAVA_HOME
echo

# Prevent CF_TRACE from causing trouble
unset CF_TRACE

#Get the App Guid for the CF App
export APP_GUID=` cf app $APP_NAME --guid`
RET_VAL=$?
if [ ${RET_VAL} != 0 ] 
then
    echo "The CF Application"  $APP_NAME "was not found"
	exit 1
fi

echo ${APP_GUID} | grep "FAIL" >/dev/null 2>&1
RET_VAL=$?
if [ ${RET_VAL} == 0 ] 
then
    echo "The Bluemix application " $APP_NAME " was not found"
	exit 1
fi

#Use the <CF APP URL>/env to get the VCAP
cf curl /v2/apps/${APP_GUID}/env > ../usr/config/.vcap_props
RET_VAL=$?
if [ ${RET_VAL} != 0 ] 
then
	echo "Error occurred. Could not retrieve the environment details of the App " ${APP_NAME}
	if [ -f ../usr/config/.vcap_props ]
	then
		rm -f ../usr/config/.vcap_props
	fi
	exit 1
fi

cat ../usr/config/.vcap_props | grep $DB_SRV_NAME >/dev/null 2>&1
RET_VAL=$?
if [ ${RET_VAL} != 0 ] 
then
    echo "Error occurred. The Bluemix application " $APP_NAME " does not contain the VCAP properties of the service" $DB_SRV_NAME ". Check if the service is bound to the app."
	if [ -f ../usr/config/.vcap_props ]
	then
		rm -f ../usr/config/.vcap_props
	fi
	exit 1
fi

cat ../usr/config/.vcap_props | grep "sqldb" >/dev/null 2>&1
RET_VAL=$?
if [ ${RET_VAL} != 0 ] 
then
	cat ../usr/config/.vcap_props | grep "cloudantNoSQLDB" >/dev/null 2>&1
	RET_VAL_CLOUDANT=$?
	if [ ${RET_VAL_CLOUDANT} != 0 ] 
then
    echo "Error occurred. Could not get information of database service type from the VCAP properties" 
	echo "Make sure that the service" $DB_SRV_NAME "is a supported database. Valid options include : 1) cloudantNoSQLDB or 2) sqldb "
	if [ -f ../usr/config/.vcap_props ]
	then
		rm -f ../usr/config/.vcap_props
	fi
	exit 1
	fi
fi


if [ -z $RUNTIME_NAME ]
then
	${JAVA_HOME}/bin/java -jar ../../mfpf-libs/mfpf-container-deployer.jar create worklightadmin ../usr/config/.vcap_props $DB_SRV_NAME 
else
	${JAVA_HOME}/bin/java -jar ../../mfpf-libs/mfpf-container-deployer.jar create worklight ../usr/config/.vcap_props $DB_SRV_NAME $RUNTIME_NAME $SCHEMA_NAME
fi

if [ -f ../usr/config/.vcap_props ]
then
	rm -f ../usr/config/.vcap_props
fi
