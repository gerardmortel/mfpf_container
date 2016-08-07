#   Licensed Materials - Property of IBM
#   5725-I43 (C) Copyright IBM Corp. 2011, 2015. All Rights Reserved.
#   US Government Users Restricted Rights - Use, duplication or
#   disclosure restricted by GSA ADP Schedule Contract with IBM Corp.

#!/usr/bin/bash

usage()
{
   echo
   echo " Running the MobileFirst Operational Analytics Image as a Container "
   echo " -----------------------------------------------------------------------------"
   echo " This script runs the MobileFirst Operational Analytics image as a container"
   echo " on the IBM Containers service on Bluemix."
   echo " Prerequisite: The prepareanalytics.sh script must be run before running this script."
   echo
   echo " Silent Execution (arguments provided as command line arguments): "
   echo "   USAGE: startanalytics.sh <command-line arguments>"
   echo "   command-line arguments: "
   echo "     -t | --tag  ANALYTICS_IMAGE_TAG       Name of the analytics image"
   echo "     -n | --name ANALYTICS_CONTAINER_NAME  Name of the analytics container"
   echo "     -i | --ip   ANALYTICS_IP              IP address the analytics container should be bound to."
   echo "											You can provide an available public IP or request one using cf ic ip request command"
   echo "     -h | --http EXPOSE_HTTP               (Optional) Expose HTTP Port. Accepted values are Y (default) or N"
   echo "     -s | --https EXPOSE_HTTPS             (Optional) Expose HTTPS Port. Accepted values are Y (default) or N"
   echo "     -m | --memory SERVER_MEM              (Optional) Assign a memory limit to the container in megabytes (MB)"
   echo "                                             Accepted values are 1024 (default), 2048,..."
   echo "     -se | --ssh SSH_ENABLE                (Optional) Enable SSH for the container. Accepted values are Y (default) or N"
   echo "     -sk | --sshkey SSH_KEY                (Optional) SSH Key to be injected into the container"
   echo "     -tr | --trace TRACE_SPEC              (Optional) Trace specification to be applied to MobileFirst Server"
   echo "     -ml | --maxlog MAX_LOG_FILES          (Optional) Maximum number of log files to maintain before overwriting"
   echo "     -ms | --maxlogsize MAX_LOG_FILE_SIZE  (Optional) Maximum size of a log file"
   echo "     -v | --volume ENABLE_VOLUME           (Optional) Enable mounting volume for container logs. Accepted values are Y or N (default)"
   echo "     -ev | --enabledatavolume ENABLE_ANALYTICS_DATA_VOLUME       (Optional) Enable mounting volume for analytics data. Accepted values are Y or N (default)"
   echo "     -av | --datavolumename ANALYTICS_DATA_VOLUME_NAME           (Optional) Specify name of the volume to be created and mounted for analytics data. Default value is mfpf_analytics_<ANALYTICS_CONTAINER_NAME>"
   echo "     -ad | --analyticsdatadirectory ANALYTICS_DATA_DIRECTORY     (Optional) Specify the directory to be used for storing analytics data. Default value is /analyticsData"
   echo "     -e | --env MFPF_PROPERTIES            (Optional) Provide related MobileFirst Operational Analytics image properties as comma-separated"
   echo "                                             key:value pairs. Example: serviceContext:analytics-service"
   echo
   echo " Silent Execution (arguments loaded from file): "
   echo "   USAGE: startanalytics.sh <path to the file from which arguments are read>"
   echo "          See args/startanalytics.properties for the list of arguments."
   echo
   echo " Interactive Execution: "
   echo "   USAGE: startanalytics.sh"
   echo
   exit 1
}

readParams()
{

   # Read the Name of the MobileFirst Operational Analytics image 
   #-------------------------------------------------------------
   INPUT_MSG="Specify the name of the analytics image. Should be of form registryUrl/repositoryNamespace/imagename (mandatory) : "
   ERROR_MSG="Name for analytics image cannot be empty. Specify the name for the analytics image. Should be of form registryUrl/repositoryNamespace/imagename (mandatory) : "
   ANALYTICS_IMAGE_TAG=$(fnReadInput "$INPUT_MSG" "$ERROR_MSG")

   # Read the name of the MobileFirst Operational Analytics container  
   #-----------------------------------------------------------------
   INPUT_MSG="Specify the name for the analytics container (mandatory) : "
   ERROR_MSG="Analytics Container name cannot be empty. Specify the name for the analytics container (mandatory) : "
   ANALYTICS_CONTAINER_NAME=$(fnReadInput "$INPUT_MSG" "$ERROR_MSG")

   # Read the IP for the MobileFirst Operational Analytics container 
   #----------------------------------------------------------------
   INPUT_MSG="Specify the IP address for the analytics container (mandatory) : "
   ERROR_MSG="Incorrect IP Address. Specify a valid IP address for the analytics container (mandatory) : "
   ANALYTICS_IP=$(fnReadIP "$INPUT_MSG" "$ERROR_MSG")

   # Expose HTTP/HTTPS Port 
   #-----------------------
   INPUT_MSG="Expose HTTP Port. Accepted values are Y or N. The default value is Y. (optional) : "
   ERROR_MSG="Input should be either Y or N. Expose HTTP Port. Accepted values are Y or N. The default value is Y. (optional) : "
   EXPOSE_HTTP=$(readBoolean "$INPUT_MSG" "$ERROR_MSG" "Y")

   INPUT_MSG="Expose HTTPS Port. Accepted values are Y or N. The default value is Y. (optional) : "
   ERROR_MSG="Input should be either Y or N. Expose HTTPS Port. Accepted values are Y or N. The default value is Y. (optional) : "
   EXPOSE_HTTPS=$(readBoolean "$INPUT_MSG" "$ERROR_MSG" "Y")

   # Read the memory for the server container 
   #-----------------------------------------
   INPUT_MSG="Specify the memory size limit (in MB) for the server container. Accepted values are 1024, 2048,.... The default value is 1024 MB. (optional) : "
   ERROR_MSG="Error due to non-numeric input. Specify a valid number (in MB) for the memory size limit. Valid values are 1024, 2048,... The default value is 1024 MB (optional) : "
   SERVER_MEM=$(fnReadNumericInput "$INPUT_MSG" "$ERROR_MSG" "1024")

   # Read the SSH details  
   #---------------------
   INPUT_MSG="Enable SSH For the server container. Accepted values are Y or N. The default value is Y. (optional) : " 
   ERROR_MSG="Input should be either Y or N. Enable SSH For the server container. Accepted values are Y or N. The default value is Y. (optional) : "
   SSH_ENABLE=$(readBoolean "$INPUT_MSG" "$ERROR_MSG" "Y")

   # Read the SSH details
   #---------------------
   if [ "$SSH_ENABLE" = "Y" ] || [ "$SSH_ENABLE" = "y" ]
   then
      read -p "Provide an SSH Key to be injected into the container. Provide the contents of your id_rsa.pub file (optional): " SSH_KEY
   fi

   # Read the Mounting Volume for server Data
   #------------------------------------------
   INPUT_MSG="Enable mounting volume for the server container logs. Accepted values are Y or N. The default value is N. (optional) : "
   ERROR_MSG="Input should be either Y or N. Enable mounting volume for the server container logs. Accepted values are Y or N. The default value is N. (optional) : " 
   ENABLE_VOLUME=$(readBoolean "$INPUT_MSG" "$ERROR_MSG" "N")

   # Read the Mounting Volume for Analytics Data details  
   #----------------------------------------------------
   INPUT_MSG="Enable mounting volume for analytics data. Accepted values are Y or N. The default value is N. (optional) : "
   ERROR_MSG="Input should be either Y or N. Enable mounting volume for analytics data. Accepted values are Y or N. The default value is N. (optional) : "
   ENABLE_ANALYTICS_DATA_VOLUME=$(readBoolean "$INPUT_MSG" "$ERROR_MSG" "N")

   if [ "$ENABLE_ANALYTICS_DATA_VOLUME" = "Y" ] || [ "$ENABLE_ANALYTICS_DATA_VOLUME" = "y" ]
   then   
       read -p "Specify name of the volume to be created and mounted for analytics data. Default value is mfpf_analytics_<ANALYTICS_CONTAINER_NAME> (optional) : " ANALYTICS_DATA_VOLUME_NAME
   fi
   
   read -p "Specify the directory to be used for storing analytics data. The default value is /analyticsData (optional) : " ANALYTICS_DATA_DIRECTORY

   # Read the Trace details  
   #-----------------------  
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
   read -p "Specify related MobileFirst Operational Analytics properties as comma-separated key:value pairs (optional) : "

}

validateParams()
{

	if [ -z "$ANALYTICS_IMAGE_TAG" ]
	then
    	echo Analytics Image Name is empty. A mandatory argument must be specified. Exiting...
		exit 0
	fi
	
	if [ -z "$ANALYTICS_CONTAINER_NAME" ]
	then
   		echo Analytics Container Name is empty. A mandatory argument must be specified. Exiting...
		exit 0
	fi

	if [ -z "$ANALYTICS_IP" ]
	then
    	echo Analytics Container IP Address field is empty. A mandatory argument must be specified. Exiting...
		exit 0
	fi
	
	if [ "$(valid_ip $ANALYTICS_IP)" = "1" ]
	then
		echo Analytics Container IP Address is incorrect. Exiting...
	    exit 0
	fi

	if [ -z "$SERVER_MEM" ]
	then
		SERVER_MEM=1024
	fi

	if [ "$(isNumber $SERVER_MEM)" = "1" ]
    then
		echo  Required Analytics Container Memory must be a Number. Exiting...
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

	if [ -z "$ENABLE_ANALYTICS_DATA_VOLUME" ]
	then
		ENABLE_ANALYTICS_DATA_VOLUME=N
	fi   

	if [ "$(validateBoolean $ENABLE_ANALYTICS_DATA_VOLUME)" = "1" ]
    then
        echo  Invalid Value for ENABLE_ANALYTICS_DATA_VOLUME. Values must be either Y / N. Exiting...
	    exit 0
    fi
   
	if [ -z "$ANALYTICS_DATA_VOLUME_NAME" ]
	then
		ANALYTICS_DATA_VOLUME_NAME=mfpf_analytics_$ANALYTICS_CONTAINER_NAME
	fi   
    
	if [ -z "$ANALYTICS_DATA_DIRECTORY" ]
	then
		ANALYTICS_DATA_DIRECTORY=/analyticsData
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
        echo  Invalid Value for EXPOSE_HTTPS. Values must either Y / N. Exiting...
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
            ANALYTICS_IMAGE_TAG="$2";
            shift
            ;;
         -n | --name)
            ANALYTICS_CONTAINER_NAME="$2";
            shift
            ;;
         -i | --ip)
            ANALYTICS_IP="$2";
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
         -ev | --enabledatavolume)
            ENABLE_ANALYTICS_DATA_VOLUME="$2";
            shift
            ;;   
         -av | --datavolumename)
            ANALYTICS_DATA_VOLUME_NAME="$2";
            shift
            ;; 
         -ad | --analyticsdatadirectory)
            ANALYTICS_DATA_DIRECTORY="$2";
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
         -m | --memory)
            SERVER_MEM="$2";
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
echo "ANALYTICS_IMAGE_NAME : " $ANALYTICS_IMAGE_TAG
echo "ANALYTICS_CONTAINER_NAME : " $ANALYTICS_CONTAINER_NAME
echo "ANALYTICS_IP : " $ANALYTICS_IP
echo "SSH_ENABLE : " $SSH_ENABLE
echo "ENABLE_VOLUME : " $ENABLE_VOLUME
echo "ENABLE_ANALYTICS_DATA_VOLUME : " $ENABLE_ANALYTICS_DATA_VOLUME
echo "ANALYTICS_DATA_VOLUME_NAME : " $ANALYTICS_DATA_VOLUME_NAME
echo "ANALYTICS_DATA_DIRECTORY : " $ANALYTICS_DATA_DIRECTORY
echo "EXPOSE_HTTP : " $EXPOSE_HTTP
echo "EXPOSE_HTTPS : " $EXPOSE_HTTPS
echo "SERVER_MEM : " $SERVER_MEM
echo "SSH_KEY : " $SSH_KEY
echo "TRACE_SPEC : " $TRACE_SPEC
echo "MAX_LOG_FILES : " $MAX_LOG_FILES
echo "MAX_LOG_FILE_SIZE : " $MAX_LOG_FILE_SIZE
echo "MFPF_PROPERTIES : " $MFPF_PROPERTIES
echo

cmd="cf ic run --name $ANALYTICS_CONTAINER_NAME -m $SERVER_MEM -p $ANALYTICS_IP:9500:9500"
if [ "$SSH_ENABLE" = "Y" ] || [ "$SSH_ENABLE" = "y" ]
then
	cmd="$cmd -p $ANALYTICS_IP:22:22"
fi

if [ "$ENABLE_VOLUME" = "Y" ] || [ "$ENABLE_VOLUME" = "y" ]
then
	createVolumes
	cmd="$cmd -v $SYSVOL_NAME:$SYSVOL_PATH"
	cmd="$cmd -v $LIBERTYVOL_NAME:$LIBERTYVOL_PATH"
	cmd="$cmd --env LOG_LOCATIONS=$SYSVOL_PATH/syslog,$LIBERTYVOL_PATH/messages.log,$LIBERTYVOL_PATH/console.log,$LIBERTYVOL_PATH/trace.log"
fi

if [ "$ENABLE_ANALYTICS_DATA_VOLUME" = "Y" ] || [ "$ENABLE_ANALYTICS_DATA_VOLUME" = "y" ]
then
	createDataVolume
	cmd="$cmd -v $ANALYTICS_DATA_VOLUME_NAME:$ANALYTICS_DATA_DIRECTORY -e ANALYTICS_DATA_DIRECTORY=$ANALYTICS_DATA_DIRECTORY  "
else
	cmd="$cmd -e ANALYTICS_DATA_DIRECTORY=$ANALYTICS_DATA_DIRECTORY  "
fi

if [ "$EXPOSE_HTTP" = "Y" ] || [ "$EXPOSE_HTTP" = "y" ]
then
	cmd="$cmd -p $ANALYTICS_IP:$ANALYTICS_HTTPPORT:$ANALYTICS_HTTPPORT"
fi

if [ "$EXPOSE_HTTPS" = "Y" ] || [ "$EXPOSE_HTTPS" = "y" ]
then
	cmd="$cmd -p $ANALYTICS_IP:$ANALYTICS_HTTPSPORT:$ANALYTICS_HTTPSPORT"
fi

if [ ! -z "$MFPF_PROPERTIES" ]
then
	cmd="$cmd -e mfpfproperties=$MFPF_PROPERTIES"
fi

if [ ! -z "$SSH_KEY" ] && ([ "$SSH_ENABLE" = "Y" ] || [ "$SSH_ENABLE" = "y" ])
then
	cmd="$cmd -e CCS_SSH_KEY=$SSH_KEY"
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

cmd="$cmd -e ANALYTICS_TRACE_LEVEL=$TRACE_SPEC -e ANALYTICS_MAX_LOG_FILES=$MAX_LOG_FILES -e ANALYTICS_MAX_LOG_FILE_SIZE=$MAX_LOG_FILE_SIZE"
cmd="$cmd $ANALYTICS_IMAGE_TAG"

echo "Starting the analytics container : " $ANALYTICS_CONTAINER_NAME
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

ANALYTICS_CONTAINER_ID=`echo $CMD_RUN_RESULT | cut -f1 -d " "`

sleep 10s
echo
echo "Checking the status of the Container $ANALYTICS_CONTAINER_NAME (id : $ANALYTICS_CONTAINER_ID) ..."

COUNTER=40
while [ $COUNTER -gt 0 ]
do
    CONTAINER_RUN_STATE=$(echo $(cf ic inspect $ANALYTICS_CONTAINER_ID | grep '"ContainerState": "Running"' | wc -l ))
    if [ $(echo $CONTAINER_RUN_STATE) = "1" ]
    then
        echo "Single container has been created successfully and is in Running state"
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
    CONTAINER_IP_STATE=$(echo $(cf ic inspect $ANALYTICS_CONTAINER_ID | grep \"HostIp\":\ \"$ANALYTICS_IP\" | wc -l ))
    if [ $CONTAINER_IP_STATE -ge 1 ]
    then
        echo "Container $ANALYTICS_CONTAINER_NAME (id : $ANALYTICS_CONTAINER_ID) is bound to public IP - $ANALYTICS_IP "
        echo 
        break
    fi

    # Allow to container group to come up
    sleep 5s

    COUNTER=`expr $COUNTER - 1`
done

echo "Detailed Status of the container and the binding can be verified using the following cf ic command"
echo "        cf ic inspect $ANALYTICS_CONTAINER_ID"
echo "The Analytics container will be accessible once the container is in Running state"

