#   Licensed Materials - Property of IBM 
#   5725-I43 (C) Copyright IBM Corp. 2011, 2015. All Rights Reserved.
#   US Government Users Restricted Rights - Use, duplication or
#   disclosure restricted by GSA ADP Schedule Contract with IBM Corp.  
   
#!/usr/bin/bash

usage() 
{
   echo 
   echo " Running a MobileFirst Platform Foundation Server Image as a Container "
   echo " --------------------------------------------------------------------------------- "
   echo " This script runs the MobileFirst Server image as a container"
   echo " on the IBM Containers service on Bluemix."
   echo " Prerequisite: The prepareserver.sh script must be run before running this script."
   echo
   echo " Silent Execution (arguments provided as command line arguments):"
   echo "   USAGE: startserver.sh <command line arguments> "
   echo "     -t | --tag SERVER_IMAGE_TAG        Name of the MobileFirst Server image available in the registry"
   echo "     -n | --name SERVER_CONTAINER_NAME  Name of the MobileFirst Server container"
   echo "     -i | --ip SERVER_IP                IP address that the MobileFirst Server container should be bound to."
   echo "										 You can provide an available public IP or request one using cf ic ip request command"
   echo "     -an | --appName APP_NAME           (Optional) Bluemix application name that should be bound to the container"
   echo "     -h | --http EXPOSE_HTTP            (Optional) Expose HTTP Port. Accepted values are Y (default) or N"
   echo "     -s | --https EXPOSE_HTTPS          (Optional) Expose HTTPS Port. Accepted values are Y (default) or N"
   echo "     -m | --memory SERVER_MEM           (Optional) Assign a memory size limit to the container in megabytes (MB)"
   echo "                                          Accepted values are 1024 (default), 2048,..."
   echo "     -se | --ssh SSH_ENABLE             (Optional) Enable SSH for the container. Accepted values are Y (default) or N"
   echo "     -sk | --sshkey SSH_KEY             (Optional) SSH Key to be injected into the container"
   echo "     -tr | --trace TRACE_SPEC           (Optional) Trace specification to be applied to MobileFirst Server"
   echo "     -ml | --maxlog MAX_LOG_FILES       (Optional) Maximum number of log files to maintain before overwriting"
   echo "     -ms | --maxlogsize MAX_LOG_FILE_SIZE (Optional) Maximum size of a log file"
   echo "     -v | --volume ENABLE_VOLUME        (Optional) Enable mounting volume for container logs"
   echo "                                          Accepted values are Y or N (default)"
   echo "     -e | --env MFPF_PROPERTIES         (Optional) MobileFirst Platform Foundation properties as comma-separated key:value pairs"
   echo "					   Example: wl.analytics.url:http://127.0.0.1/analytics-service/v2,wl.analytics.console.url:http://127.0.0.1/analytics/console" 
   echo 
   echo " Silent Execution (arguments loaded from file):"
   echo "   USAGE: startserver.sh <path to the file from which arguments are read>"
   echo "          See args/startserver.properties for the list of arguments."
   echo 
   echo " Interactive Execution: "
   echo "   USAGE: startserver.sh"
   echo
   exit 1
}

readParams()
{
        
   # Read the name of the MobileFirst Server image
   #----------------------------------------------
   INPUT_MSG="Specify the name of the MobileFirst Server image available in the Bluemix registry. Should be of form registryUrl/repositoryNamespace/name (mandatory) : "
   ERROR_MSG="Name of the MobileFirst Server image cannot be empty. Specify the name of the MobileFirst Server image available in the Bluemix registry (mandatory) : "
   SERVER_IMAGE_TAG=$(fnReadInput "$INPUT_MSG" "$ERROR_MSG")

   # Read the name of the container 
   #-------------------------------
   INPUT_MSG="Specify the name of the container (mandatory) : " 
   ERROR_MSG="Container name cannot be empty. Specify the name of the container (mandatory) : "
   SERVER_CONTAINER_NAME=$(fnReadInput "$INPUT_MSG" "$ERROR_MSG")

   # Read the IP address for the MobileFirst Server container 
   #---------------------------------------------------------
   INPUT_MSG="Specify the IP address for the MobileFirst Server container (mandatory) : "
   ERROR_MSG="Incorrect IP address. Specify the correct IP address for the MobileFirst Server container (mandatory) : " 
   SERVER_IP=$(fnReadIP "$INPUT_MSG" "$ERROR_MSG")

   # Read the Bluemix application name
   #-----------------------------------
   read -p "Specify the Bluemix application name that should be bound to the container (optional) : " APP_NAME

   # Expose HTTP/HTTPS Port
   #------------------------
   INPUT_MSG="Expose HTTP Port. Accepted values are Y or N. The default value is Y. (optional) : " 
   ERROR_MSG="Input should be either Y or N. Expose HTTP Port. Accepted values are Y or N. The default value is Y. (optional) : "
   EXPOSE_HTTP=$(readBoolean "$INPUT_MSG" "$ERROR_MSG" "Y")

   INPUT_MSG="Expose HTTPS Port. Accepted values are Y or N. The default value is Y. (optional) : " 
   ERROR_MSG="Input should be either Y or N. Expose HTTPS Port. Accepted values are Y or N. The default value is Y. (optional) : "
   EXPOSE_HTTPS=$(readBoolean "$INPUT_MSG" "$ERROR_MSG" "Y")

   # Read the memory size for the MobileFirst Server container
   #-----------------------------------------
   INPUT_MSG="Specify the memory size limit (in MB) for the MobileFirst Server container. Accepted values are 1024, 2048,... The default value is 1024 (optional) : "
   ERROR_MSG="Error due to non-numeric input. Specify a valid value. Valid values are 1024, 2048,... The default value is 1024 (optional) : "
   SERVER_MEM=$(fnReadNumericInput "$INPUT_MSG" "$ERROR_MSG" "1024")

   # Read the SSH/Mounting Volume/Trace Spec details
   #------------------------------------------------
   INPUT_MSG="Enable SSH For the MobileFirst Server container. Accepted values are Y or N. The default value is Y. (optional) : "
   ERROR_MSG="Input should be either Y or N. Enable SSH For the MobileFirst Server container. Accepted values are Y or N. The default value is Y. (optional) : "
   SSH_ENABLE=$(readBoolean "$INPUT_MSG" "$ERROR_MSG" "Y")

   if [ "$SSH_ENABLE" = "Y" ] || [ "$SSH_ENABLE" = "y" ]
   then
      read -p "Provide an SSH Key to be injected into the container. Provide the contents of your id_rsa.pub file (optional): " SSH_KEY
   fi
 
   INPUT_MSG="Enable mounting volume for the MobileFirst Server container logs. Accepted values are Y or N. The default value is N (optional) : " 
   ERROR_MSG="Input should be either Y or N. Enable mounting volume for the MobileFirst Server container logs. Accepted values are Y or N. The default value is N (optional) : " 
   ENABLE_VOLUME=$(readBoolean "$INPUT_MSG" "$ERROR_MSG" "N")
   
   read -p "Provide the Trace specification to be applied to the MobileFirst Server. The default value is *=info (optional): " TRACE_SPEC

   # Read the maximum number of log files
   #-------------------------------------
   INPUT_MSG="Provide the maximum number of log files to maintain before overwriting them. The default value is 5 files. (optional): " 
   ERROR_MSG="Error due to non-numeric input. Provide the maximum number of log files to maintain before overwriting them. The default value is 5 files. (optional): " 
   MAX_LOG_FILES=$(fnReadNumericInput "$INPUT_MSG" "$ERROR_MSG" "5")

   # Maximum size of a log file in MB
   #----------------------------------
   INPUT_MSG="Maximum size of a log file (in MB). The default value is 20 MB. (optional): "
   ERROR_MSG="Error due to non-numeric input. Specify a number to represent the maximum log file size (in MB) allowed. The default value is 20 MB. (optional): " 
   MAX_LOG_FILE_SIZE=$(fnReadNumericInput "$INPUT_MSG" "$ERROR_MSG" "20")

   # Specify the MFP related properties 
   #-----------------------------------   
   read -p "Specify related MobileFirst Platform Foundation properties as comma-separated key:value pairs (optional) : " MFPF_PROPERTIES

}

validateParams() 
{

	if [ -z "$SERVER_IMAGE_TAG" ]
	then
    		echo Server Image Name is empty. A mandatory argument must be specified. Exiting...
			exit 0
	fi
	
	if [ -z "$SERVER_CONTAINER_NAME" ]
	then
    		echo Server Container Name is empty. A mandatory argument must be specified. Exiting...
			exit 0
	fi

	if [ -z "$SERVER_IP" ]
	then
    		echo Server Container IP Address field is empty. A mandatory argument must be specified. Exiting...
			exit 0
	fi
	
	if [ "$(valid_ip $SERVER_IP)" = "1" ]
	then
		    echo Server Container IP Address is incorrect. Exiting...
	        exit 0
	fi

   if [ -z "$SERVER_MEM" ]
   then 
    SERVER_MEM=1024
   fi

	if [ "$(isNumber $SERVER_MEM)" = "1" ]
    then
        echo  Required Server Container Memory must be a number. Exiting...
	    exit 0
    fi

   if [ -z "$SSH_ENABLE" ]
   then 
      SSH_ENABLE=Y
   fi

	if [ "$(validateBoolean $SSH_ENABLE)" = "1" ]
    then
        echo  Invalid Value for SSH_ENABLE. Values must be either Y / N. Exiting...
	    exit 0
    fi

   if [ -z "$ENABLE_VOLUME" ]
   then 
      ENABLE_VOLUME=N
   fi

	if [ "$(validateBoolean $ENABLE_VOLUME)" = "1" ]
    then
        echo  Invalid Value for ENABLE_VOLUME. Values must be either Y / N. Exiting...
	    exit 0
    fi
   
   if [ -z "$EXPOSE_HTTP" ]
   then 
      EXPOSE_HTTP=Y
   fi

	if [ "$(validateBoolean $EXPOSE_HTTP)" = "1" ]
    then
        echo  Invalid Value for EXPOSE_HTTP. Values must be either Y / N. Exiting...
	    exit 0
    fi

   if [ -z "$EXPOSE_HTTPS" ]
   then 
      EXPOSE_HTTPS=Y
   fi

	if [ "$(validateBoolean $EXPOSE_HTTPS)" = "1" ]
    then
        echo  Invalid Value for EXPOSE_HTTPS. Values must be either Y / N. Exiting...
	    exit 0
    fi
}
cd "$( dirname "$0" )"

source ./common.sh
source ../usr/env/server.env
  
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
         -n | --name)
            SERVER_CONTAINER_NAME="$2";
            shift
            ;;
         -m | --memory)
            SERVER_MEM="$2";
            shift
            ;;
         -i | --ip)
            SERVER_IP="$2";
            shift
            ;;
         -an | --appName)
            APP_NAME="$2";
            shift
            ;;
         -se | --ssh)
            SSH_ENABLE="$2";
            shift
            ;;
         -v | --volume)
            ENABLE_VOLUME="$2";
            shift
            ;;
         -h | --http)
            EXPOSE_HTTP="$2";
            shift
            ;;
         -s | --https)
            EXPOSE_HTTPS="$2";
            shift
            ;;
         -e | --env)
         	MFPF_PROPERTIES="$2";
         	shift
         	;;
         -sk | --sshkey)
            SSH_KEY="$2";
            shift
            ;;
         -tr | --trace)
            TRACE_SPEC="$2";
            shift
            ;;
         -ml | --maxlog)
            MAX_LOG_FILES="$2";
            shift
            ;;
         -ms | --maxlogsize)
            MAX_LOG_FILE_SIZE="$2";
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
echo "SERVER_IMAGE_NAME : " $SERVER_IMAGE_TAG
echo "SERVER_CONTAINER_NAME : " $SERVER_CONTAINER_NAME
echo "SERVER_MEM : " $SERVER_MEM
echo "SERVER_IP : " $SERVER_IP
echo "APP_NAME : " $APP_NAME
echo "EXPOSE_HTTP : " $EXPOSE_HTTP
echo "EXPOSE_HTTPS : " $EXPOSE_HTTPS
echo "SSH_ENABLE : " $SSH_ENABLE
echo "ENABLE_VOLUME : " $ENABLE_VOLUME
echo "SSH_KEY : " $SSH_KEY
echo "TRACE_SPEC : " $TRACE_SPEC
echo "MAX_LOG_FILES : " $MAX_LOG_FILES
echo "MAX_LOG_FILE_SIZE : " $MAX_LOG_FILE_SIZE
echo "MFPF_PROPERTIES : " $MFPF_PROPERTIES
echo 

cmd="cf ic run --name $SERVER_CONTAINER_NAME -m $SERVER_MEM"
if [ "$SSH_ENABLE" = "Y" ] || [ "$SSH_ENABLE" = "y" ]
then
   cmd="$cmd -p $SERVER_IP:22:22"
fi

if [ "$ENABLE_VOLUME" = "Y" ] || [ "$ENABLE_VOLUME" = "y" ]
then
   createVolumes
   cmd="$cmd -v $SYSVOL_NAME:$SYSVOL_PATH"
   cmd="$cmd -v $LIBERTYVOL_NAME:$LIBERTYVOL_PATH"
   cmd="$cmd --env LOG_LOCATIONS=$SYSVOL_PATH/syslog,$LIBERTYVOL_PATH/messages.log,$LIBERTYVOL_PATH/console.log,$LIBERTYVOL_PATH/trace.log"
fi

if [ "$EXPOSE_HTTP" = "Y" ] || [ "$EXPOSE_HTTP" = "y" ]
then
   cmd="$cmd -p $SERVER_IP:$MFPF_SERVER_HTTPPORT:$MFPF_SERVER_HTTPPORT"
fi

if [ "$EXPOSE_HTTPS" = "Y" ] || [ "$EXPOSE_HTTPS" = "y" ]
then
	cmd="$cmd -p $SERVER_IP:$MFPF_SERVER_HTTPSPORT:$MFPF_SERVER_HTTPSPORT"
fi

if [ ! -z "$APP_NAME" ]
then 
	cmd="$cmd -e CCS_BIND_APP=$APP_NAME"
fi

if [ ! -z "$MFPF_PROPERTIES" ]
then
	cmd="$cmd -e mfpfproperties=$MFPF_PROPERTIES"
fi

if [ -z "$TRACE_SPEC" ]
then
	TRACE_SPEC="*=info"
fi

if [ -z "$MAX_LOG_FILES" ]
then
	MAX_LOG_FILES="5"
fi

if [ -z "$MAX_LOG_FILE_SIZE" ]
then
	MAX_LOG_FILE_SIZE="20"
fi

TRACE_SPEC=${TRACE_SPEC//"="/"~"}

cmd="$cmd -e TRACE_LEVEL=$TRACE_SPEC -e MAX_LOG_FILES=$MAX_LOG_FILES -e MAX_LOG_FILE_SIZE=$MAX_LOG_FILE_SIZE"

if [ ! -z "$SSH_KEY" ] && ([ "$SSH_ENABLE" = "Y" ] || [ "$SSH_ENABLE" = "y" ])
then
	cmd="$cmd -e CCS_SSH_KEY=$SSH_KEY"
fi

cmd="$cmd $SERVER_IMAGE_TAG"
echo "Starting the MobileFirst Server container : " $SERVER_CONTAINER_NAME
echo "Executing command : " $cmd

CMD_RUN_RESULT=`eval ${cmd}`
echo
echo "$CMD_RUN_RESULT"

GREPPED_RESULT=$(echo $CMD_RUN_RESULT | grep -i "Error" | wc -l | tr -s " ")

if [ $(echo $GREPPED_RESULT) != "0" ]
then
    echo "ERROR: cf ic run command failed. Exiting ..."
	exit 1
fi

SERVER_CONTAINER_ID=`echo $CMD_RUN_RESULT | cut -f1 -d " "`

sleep 10s
echo
echo "Checking the status of the Container $SERVER_CONTAINER_NAME (id : $SERVER_CONTAINER_ID) ..."

COUNTER=40
while [ $COUNTER -gt 0 ]
do
    CONTAINER_RUN_STATE=$(echo $(cf ic inspect $SERVER_CONTAINER_ID | grep '"ContainerState": "Running"' | wc -l ))
    if [ $(echo $CONTAINER_RUN_STATE) = "1" ]
    then
        echo "MobileFirst Server Container has been created successfully and is in Running state"
        echo 
        break
    fi

    # Allow to container group to come up
    sleep 5s

    COUNTER=`expr $COUNTER - 1`
done

echo "Checking the status of the public IP binding to the Container ..."

COUNTER=40
while [ $COUNTER -gt 0 ]
do
    CONTAINER_IP_STATE=$(echo $(cf ic inspect $SERVER_CONTAINER_ID | grep \"HostIp\":\ \"$SERVER_IP\" | wc -l ))
    if [ $CONTAINER_IP_STATE -ge 1 ]
    then
        echo "Container $SERVER_CONTAINER_NAME (id : $SERVER_CONTAINER_ID) is bound to public IP - $SERVER_IP "
        echo 
        break
    fi

    # Allow to container group to come up
    sleep 5s

    COUNTER=`expr $COUNTER - 1`
done

echo "Detailed Status of the container and the binding can be verified using the following cf ic command"
echo "        cf ic inspect $SERVER_CONTAINER_ID"
echo 
