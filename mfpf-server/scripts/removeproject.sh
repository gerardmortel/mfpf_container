#   Licensed Materials - Property of IBM 
#   5725-I43 (C) Copyright IBM Corp. 2011, 2015. All Rights Reserved.
#   US Government Users Restricted Rights - Use, duplication or
#   disclosure restricted by GSA ADP Schedule Contract with IBM Corp.  
   
#!/usr/bin/bash


usage() 
{
   echo 
   echo " Removing a project from the MobileFirst Server Image "
   echo " -------------------------------------------------------------------------- "
   echo " This script removes a project from the IBM MobileFirst Platform Foundation configuration."
   echo " After running this script, then run the prepareserver.sh script."
   echo
   echo " Silent Execution (arguments provided as command-line arguments) : "
   echo "   USAGE: removeproject.sh <command-line arguments> "
   echo "   command-line arguments: "
   echo "     -r | --runtime RUNTIME_NAME             The name of the runtime to be removed."
   echo "     -i | --ip SERVER_IP                     The IP address or route the MobileFirst Server container is bound to."
   echo "     -p | --port SERVER_PORT                 The HTTPS port number exposed on the MobileFirst Server container."
   echo "    -lu | --libertyadminusername LIBERTY_ADMIN_USERNAME User name of the Liberty administrator role"
   echo "    -lp | --libertyadminpassword LIBERTY_ADMIN_PASSWORD Password of the Liberty administrator role"
   echo "     -u | --mfpfadminusername MFPF_ADMIN_USERNAME     User name of MobileFirst Server administrator"
   echo "    -pa | --mfpfadminpassword MFPF_ADMIN_PASSWORD    Password of MobileFirst Server administrator"
   echo "     -d | --deletedata DELETE_RUNTIME_DATA   (Optional) Confirmation to delete the project-related data"
   echo "                                               from the database. Accepted values are Y or N (default)."
   echo "     -an | --appname APP_NAME                The Bluemix application name."
   echo "      -n | --servicename DB_SRV_NAME         The Bluemix database service instance name."
   echo "     -sn | --schema SCHEMA_NAME              (Optional) Schema name (defaults to runtime name for runtime database)"
   echo "     -ar | --adminroot MFPF_ADMIN_ROOT        (Optional) Admin context path of the MobileFirst Server. (defaults to worklightadmin if not specified)"
   echo "     -dp | --deleteproject DELETE_RUNTIME_PROJECT (Optional) Confirmation to delete the runtime project from the"
   echo "                                                    projects folder. Accepted values are Y or N (default)."
   echo "     -ce | --certpath CERTIFICATE_PATH       (Optional) Provide the path to the folder containing server certificates to perform the HTTPS operations."
   echo
   echo " Silent Execution (arguments loaded from file):"
   echo "   USAGE: removeproject.sh <path to the file from which arguments are read>"
   echo "          See args/removeproject.properties for the list of arguments."
   echo 
   echo " Interactive Execution: "
   echo "   USAGE: removeproject.sh"
   echo
   exit 1
}

readParams()
{

   # Read the project to be deleted 
   #-------------------------------
   INPUT_MSG="Specify the name of the project to delete (mandatory) : "
   ERROR_MSG="Project name cannot be empty. Specify the name of the project to delete (mandatory) : "
   RUNTIME_NAME=$(fnReadInput "$INPUT_MSG" "$ERROR_MSG")
      
   # Read the IP address for the MobileFirst Server container 
   #---------------------------------------------------------
   INPUT_MSG="Specify the IP address of the MobileFirst Server container (mandatory) : "
   ERROR_MSG="Incorrect IP address. Specify the correct IP address of the MobileFirst Server container (mandatory) : " 
   SERVER_IP=$(fnReadIP "$INPUT_MSG" "$ERROR_MSG")

   # Read the HTTPS port that is exposed on the MobileFirst Server container
   #------------------------------------------------------------------------
   INPUT_MSG="Specify the HTTPS port number that is exposed on the MobileFirst Server container (mandatory) : " 
   ERROR_MSG="Error due to non-numeric input. Specify the HTTPS port number that is exposed on the MobileFirst Server container. (mandatory) : " 
   SERVER_PORT=$(fnReadPort "$INPUT_MSG" "$ERROR_MSG")

   # Read the user name of the Liberty administrator for the server
   #---------------------------------------------------------------
   INPUT_MSG="Specify the user name of the Liberty administrator for the server (mandatory) : "
   ERROR_MSG="User name cannot be empty. Specify the user name of the Liberty administrator for the server (mandatory) : "
   LIBERTY_ADMIN_USERNAME=$(fnReadInput "$INPUT_MSG" "$ERROR_MSG")

   # Read the IBM Bluemix password
   #------------------------------
   INPUT_MSG="Specify the password for the Liberty administrator for the server (mandatory) : " 
   ERROR_MSG="`echo $'\n'`Password cannot be empty. Specify the password for the Liberty administrator for the server (mandatory) : " 
   LIBERTY_ADMIN_PASSWORD=$(fnReadPassword "$INPUT_MSG" "$ERROR_MSG")
   echo ""

   # Read the user name of the Liberty administrator for the server
   #--------------------------------------------------------------
   INPUT_MSG="Specify the user name of the MobileFirst Server administrator (mandatory) : " 
   ERROR_MSG="Username is input cannot be empty. Specify the user name of the MobileFirst Server administrator (mandatory) : " 
   MFPF_ADMIN_USERNAME=$(fnReadInput "$INPUT_MSG" "$ERROR_MSG")

   # Read the MobileFirst Server administrator password
   #---------------------------------------------------
   INPUT_MSG="Specify the password for the MobileFirst Server administrator (mandatory) : "
   ERROR_MSG="`echo $'\n'`Password cannot be empty. Specify the password for the MobileFirst Server administrator (mandatory) : "
   MFPF_ADMIN_PASSWORD=$(fnReadPassword "$INPUT_MSG" "$ERROR_MSG")
   echo ""

   # Specify whether the runtime data should be deleted from the database
   #---------------------------------------------------------------------
   INPUT_MSG="Specify whether the runtime data should be deleted from the database. Accepted values are Y or N. The default value is N (optional) : "
   ERROR_MSG="Input should be either Y or N. Specify whether the runtime data should be deleted from the database. Accepted values are Y or N. The default value is N (optional) : "
   DELETE_RUNTIME_DATA=$(readBoolean "$INPUT_MSG" "$ERROR_MSG" "N")
   
   if [ "$DELETE_RUNTIME_DATA" = "Y" ] || [ "$DELETE_RUNTIME_DATA" = "y" ]
   then 

         # Read the IBM Bluemix application name
         #--------------------------------------
         INPUT_MSG="Specify your IBM Bluemix application name (mandatory) : "
         ERROR_MSG="IBM Bluemix Application Name cannot be empty. Specify your IBM Bluemix application name (mandatory) : "
         APP_NAME=$(fnReadInput "$INPUT_MSG" "$ERROR_MSG")

         # Read the IBM Bluemix Database Service name.
         #--------------------------------------------
         INPUT_MSG="Specify your IBM Bluemix Database Service name. (mandatory) : "
         ERROR_MSG="Bluemix Database Service Name cannot be empty. Specify your IBM Bluemix Database Service name. (mandatory) : "
         DB_SRV_NAME=$(fnReadInput "$INPUT_MSG" "$ERROR_MSG")

         read -p "Specify your Database schema name (defaults to the runtime name of the runtime database) (optional) : " SCHEMA_NAME
   fi
   
   read -p "Specify the context path for the Admin Root of the MobileFirst Server (defaults to worklightadmin if not specified) (optional) : " MFPF_ADMIN_ROOT

   # Specify whether the project should be deleted from the project location 
   #------------------------------------------------------------------------
   INPUT_MSG="Specify whether the project should be deleted from the projects directory (/usr/projects/) . Accepted values are Y or N. The default value is N (optional) : " 
   ERROR_MSG="Input should be either Y or N. Specify whether the project should be deleted from the projects directory. Accepted values are Y or N. The default value is N (optional) : "
   DELETE_RUNTIME_PROJECT=$(readBoolean "$INPUT_MSG" "$ERROR_MSG" "N")

   # Specify the folder path containing the server certificates to perform the curl operations over HTTPS
   #-----------------------------------------------------------------------------------------------------
   read -p "Specify the folder path containing the server certificates to perform the curl operations over HTTPS. (Uses insecure mode if not specified) (optional) : " CERTIFICATE_PATH

}

validateParams() 
{

   if [ -z "$RUNTIME_NAME" ]
   then
         echo RUNTIME_NAME is empty. A mandatory argument must be specified. Exiting...
         exit 0
   fi

   if [ -z "$SERVER_IP" ]
   then
         echo SERVER_IP is empty. A mandatory argument must be specified. Exiting...
         exit 0
   fi

   if [ -z "$SERVER_PORT" ]
   then
         echo SERVER_PORT is empty. A mandatory argument must be specified. Exiting...
         exit 0
   fi

   if [ "$(isNumber $SERVER_PORT)" = "1" ]
   then
		echo Invalid SERVER_PORT. Exiting...
		exit 0
	fi

   if [ -z "$LIBERTY_ADMIN_USERNAME" ]
   then
         echo LIBERTY_ADMIN_USERNAME is empty. A mandatory argument must be specified. Exiting...
         exit 0
   fi

   if [ -z "$LIBERTY_ADMIN_PASSWORD" ]
   then
         echo LIBERTY_ADMIN_PASSWORD is empty. A mandatory argument must be specified. Exiting...
         exit 0
   fi

   if [ -z "$MFPF_ADMIN_USERNAME" ]
   then
         echo MFPF_ADMIN_USERNAME is empty. A mandatory argument must be specified. Exiting...
         exit 0
   fi

   if [ -z "$MFPF_ADMIN_PASSWORD" ]
   then
         echo MFPF_ADMIN_PASSWORD is empty. A mandatory argument must be specified. Exiting...
         exit 0
   fi

   if [ -z "$DELETE_RUNTIME_DATA" ] 
   then     
		DELETE_RUNTIME_DATA="N"
   fi
   
   if [ "$DELETE_RUNTIME_DATA" = "Y" ] || [ "$DELETE_RUNTIME_DATA" = "y" ]
   then 
      
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
      
		if [ -z "$SCHEMA_NAME" ]
		then
			SCHEMA_NAME=$RUNTIME_NAME
		fi
   fi

   if [ -z "$MFPF_ADMIN_ROOT" ]
   then
      MFPF_ADMIN_ROOT="worklightadmin"
   fi

   if [ -z "$DELETE_RUNTIME_PROJECT" ]
   then
      DELETE_RUNTIME_PROJECT="N"
   fi
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
         -r | --runtime)
            RUNTIME_NAME="$2";
            shift
            ;;
         -i | --ip)
            SERVER_IP="$2";
            shift
            ;;
         -p | --port)
            SERVER_PORT="$2";
            shift
            ;;
         -lu | --libertyadminusername)
            LIBERTY_ADMIN_USERNAME="$2";
            shift
            ;;
         -lp | --libertyadminpassword)
            LIBERTY_ADMIN_PASSWORD="$2";
            shift
            ;;
         -u | --mfpfadminusername)
            MFPF_ADMIN_USERNAME="$2";
            shift
            ;;
         -pa | --mfpfadminpassword)
            MFPF_ADMIN_PASSWORD="$2";
            shift
            ;;
         -d | --deletedata)
            DELETE_RUNTIME_DATA="$2";
            shift
            ;;
         -dp | --deleteproject)
            DELETE_RUNTIME_PROJECT="$2";
            shift
            ;;
         -an | --appname)
            APP_NAME="$2";
            shift
            ;;
         -n | --servicename)
         	DB_SRV_NAME="$2";
         	shift
         	;;
         -sn | --schema)
         	SCHEMA_NAME="$2";
         	shift
         	;;
         -ar | --adminroot)
            MFPF_ADMIN_ROOT="$2";
            shift
            ;;
         -ce | --certpath)
            CERTIFICATE_PATH="$2";
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

echo "Arguments : "
echo "----------- "
echo 
echo "RUNTIME_NAME : " $RUNTIME_NAME
echo "SERVER CONTAINER IP : " $SERVER_IP
echo "SERVER CONTAINER PORT : " $SERVER_PORT
echo "LIBERTY ADMIN USER NAME : " $LIBERTY_ADMIN_USERNAME
echo "LIBERTY ADMIN PASSWORD : XXXXXXXX " 
echo "MFPF ADMIN USER NAME : " $MFPF_ADMIN_USERNAME
echo "MFPF ADMIN PASSWORD : XXXXXXXX "
echo "DELETE_RUNTIME_DATA : " $DELETE_RUNTIME_DATA
echo "DELETE_RUNTIME_PROJECT : " $DELETE_RUNTIME_PROJECT
echo "MFPF_ADMIN_ROOT : " $MFPF_ADMIN_ROOT
echo "CERTIFICATE_PATH : " $CERTIFICATE_PATH

if [ "$DELETE_RUNTIME_DATA" = "Y" ] || [ "$DELETE_RUNTIME_DATA" = "y" ] 
then
   echo "APP_NAME : " $APP_NAME
   echo "DB_SRV_NAME : " $DB_SRV_NAME
   echo "SCHEMA_NAME : " $SCHEMA_NAME
fi

echo 

if [ "$DELETE_RUNTIME_PROJECT" = "Y" ] || [ "$DELETE_RUNTIME_PROJECT" = "y" ]
then
	if [ -d ../usr/projects/$RUNTIME_NAME ]
	then
   		rm -rf ../usr/projects/$RUNTIME_NAME
   		echo "Deleted the project $RUNTIME_NAME from the usr/projects folder." 
	else
		echo "The project directory $RUNTIME_NAME does not exist. No more action is required."         
    fi
    
    if [ -f ../usr/projects/${RUNTIME_NAME}.war ]
    then
    	rm ../usr/projects/${RUNTIME_NAME}.war
    	echo "Deleted the project WAR from the the usr/projects folder."
    fi
else 
	echo "Warning! Ensure that the $RUNTIME_NAME project is deleted manually from the usr/projects folder." 
fi

echo "Deleting the configuration files of the $RUNTIME_NAME project..."
rm -f ../usr/config/${RUNTIME_NAME}.xml   

if [ "$DELETE_RUNTIME_DATA" = "Y" ] || [ "$DELETE_RUNTIME_DATA" = "y" ]
then
	echo "Deleting the $RUNTIME_NAME project related data from the database" 
	
	# check if user has overridden JAVA_HOME .
	if [ -z "$JAVA_HOME" ]
	then
		echo "JAVA_HOME is not set. Please set JAVA_HOME and retry."
		exit 1
	fi
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
	${JAVA_HOME}/bin/java -jar ../../mfpf-libs/mfpf-container-deployer.jar delete worklight ../usr/config/.vcap_props $DB_SRV_NAME $RUNTIME_NAME $SCHEMA_NAME
	RET_VAL=$?
	if [ ${RET_VAL} != 0 ]
	then
		echo "Exiting..."
		exit 1
	fi
fi

echo "Stopping the $RUNTIME_NAME project on the container..."

if [ -z "$CERTIFICATE_PATH" ] 
  then
	curl -sS -k -u ${LIBERTY_ADMIN_USERNAME}:${LIBERTY_ADMIN_PASSWORD} -H "Content-Type : application/json" -X POST https://${SERVER_IP}:${SERVER_PORT}/IBMJMXConnectorREST/mbeans/WebSphere:name=${RUNTIME_NAME},service=com.ibm.websphere.application.ApplicationMBean/operations/stop -d {} >/dev/null
	echo "Deleting the data related to $RUNTIME_NAME project from the management database"
	curl -sS -k -u ${MFPF_ADMIN_USERNAME}:${MFPF_ADMIN_PASSWORD} -X DELETE https://${SERVER_IP}:${SERVER_PORT}/${MFPF_ADMIN_ROOT}/management-apis/1.0/runtimes/${RUNTIME_NAME}/lock >/dev/null
	curl -sS -k -u ${MFPF_ADMIN_USERNAME}:${MFPF_ADMIN_PASSWORD} -X DELETE https://${SERVER_IP}:${SERVER_PORT}/${MFPF_ADMIN_ROOT}/management-apis/1.0/runtimes/${RUNTIME_NAME} >/dev/null
  else
    curl -sS --capath ${CERTIFICATE_PATH} -u ${LIBERTY_ADMIN_USERNAME}:${LIBERTY_ADMIN_PASSWORD} -H "Content-Type : application/json" -X POST https://${SERVER_IP}:${SERVER_PORT}/IBMJMXConnectorREST/mbeans/WebSphere:name=${RUNTIME_NAME},service=com.ibm.websphere.application.ApplicationMBean/operations/stop -d {} >/dev/null
    echo "Deleting the data related to $RUNTIME_NAME project from the management database"
    curl -sS --capath ${CERTIFICATE_PATH} -u ${MFPF_ADMIN_USERNAME}:${MFPF_ADMIN_PASSWORD} -X DELETE https://${SERVER_IP}:${SERVER_PORT}/${MFPF_ADMIN_ROOT}/management-apis/1.0/runtimes/${RUNTIME_NAME}/lock >/dev/null
    curl -sS --capath ${CERTIFICATE_PATH} -u ${MFPF_ADMIN_USERNAME}:${MFPF_ADMIN_PASSWORD} -X DELETE https://${SERVER_IP}:${SERVER_PORT}/${MFPF_ADMIN_ROOT}/management-apis/1.0/runtimes/${RUNTIME_NAME} >/dev/null
fi 

echo
echo "Operation is complete."
