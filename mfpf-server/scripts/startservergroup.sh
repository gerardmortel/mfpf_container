#   Licensed Materials - Property of IBM 
#   5725-I43 (C) Copyright IBM Corp. 2011, 2015. All Rights Reserved.
#   US Government Users Restricted Rights - Use, duplication or
#   disclosure restricted by GSA ADP Schedule Contract with IBM Corp.  
   
#!/usr/bin/bash


usage() 
{
   echo 
   echo " Running a MobileFirst Platform Foundation Server Image as a Container Group "
   echo " --------------------------------------------------------------------------------------- "
   echo " This script runs the MobileFirst Server image as a container group"
   echo " on the IBM Containers service on Bluemix."
   echo " Prerequisite: The prepareserver.sh script must be run before running this script."
   echo
   echo " Silent Execution (arguments provided as command line arguments):"
   echo "   USAGE: starservergroup.sh <command line arguments> "
   echo "   command-line arguments: "
   echo "     -t | --tag SERVER_IMAGE_TAG                  Name of the MobileFirst Server image available in the Bluemix registry"
   echo "     -gn | --name SERVER_CONTAINER_GROUP_NAME     Name of the MobileFirst Server container group"
   echo "     -gh | --host SERVER_CONTAINER_GROUP_HOST     The host name of the route"
   echo "     -gs | --domain SERVER_CONTAINER_GROUP_DOMAIN The domain name of the route"
   echo "     -gm | --min SERVERS_CONTAINER_GROUP_MIN      (Optional) The minimum number of instances. The default value is 1"
   echo "     -gx | --max SERVER_CONTAINER_GROUP_MAX       (Optional) The maximum number of instances. The default value is 2"
   echo "     -gd | --desired SERVER_CONTAINER_GROUP_DESIRED (Optional) The desired number of instances. The default value is 2"
   echo "     -a  | --auto ENABLE_AUTORECOVERY                Enable Auto-recovery option for the container instances. The default is N"
   echo "     -an | --appName APP_NAME             (Optional) The Bluemix application name that should be bound to the container"
   echo "     -tr | --trace TRACE_SPEC             (Optional) Trace specification to be applied to MobileFirst Server"
   echo "     -ml | --maxlog MAX_LOG_FILES         (Optional) Maximum number of log files to maintain before overwriting"
   echo "     -ms | --maxlogsize MAX_LOG_FILE_SIZE (Optional) Maximum size of a log file"
   echo "     -e | --env MFPF_PROPERTIES           (Optional) MobileFirst Platform Foundation properties as comma-separated key:value pairs "
   echo "     -m | --memory SERVER_MEM             (Optional) Assign a memory size limit to the container in megabytes (MB)"
   echo "                                            Accepted values are 1024 (default), 2048,..."
   echo "     -v | --volume ENABLE_VOLUME          (Optional) Enable mounting volume for the container logs" 
   echo "                                            Accepted values are Y or N (default)"
   echo 
   echo " Silent Execution (arguments loaded from file) : "
   echo "   USAGE: startservergroup.sh <path to the file from which arguments are read>"
   echo "          See args/startservergroup.properties for the list of arguments."
   echo 
   echo " Interactive Execution: "
   echo "   USAGE: startservergroup.sh"
   echo
   exit 1
}

readParams()
{

      # Read the name of the MobileFirst Server image
      #----------------------------------------------
      INPUT_MSG="Specify the name of the MobileFirst Server image available in the Bluemix registry. Should be of form registryUrl/repositoryNamespace/imagename (mandatory) : "
      ERROR_MSG="Name of the server image cannot be empty. Specify the name of the MobileFirst Server image. Should be of form registryUrl/repositoryNamespace/imagename (mandatory) : "
      SERVER_IMAGE_TAG=$(fnReadInput "$INPUT_MSG" "$ERROR_MSG")

      # Read the name of the container 
      #-------------------------------
      INPUT_MSG="Specify the name for the MobileFirst Server container group (mandatory) : "
      ERROR_MSG="Container group name cannot be empty. Specify the name for the MobileFirst Server container group (mandatory) : "
      SERVER_CONTAINER_GROUP_NAME=$(fnReadInput "$INPUT_MSG" "$ERROR_MSG")

      # Read the minimum number of instances
      #-------------------------------------
      INPUT_MSG="Specify the minimum number of instances. The default value is 1 (optional) : "
      ERROR_MSG="Error due to non-numeric input. Specify the minimum number of instances. The default value is 1 (optional) : "
      SERVER_CONTAINER_GROUP_MIN=$(fnReadNumericInput "$INPUT_MSG" "$ERROR_MSG" "1")

      # Read the maximum number of instances
      #-------------------------------------
      INPUT_MSG="Specify the maximum number of instances. The default value is 2 (optional) : "
      ERROR_MSG="Error due to non-numeric input. Specify the maximum number of instances. The default value is 2 (optional) : "
      SERVER_CONTAINER_GROUP_MAX=$(fnReadNumericInput "$INPUT_MSG" "$ERROR_MSG" "2")

      # Read the desired number of instances
      #-------------------------------------
      INPUT_MSG="Specify the number of instances to create. The default value is 2 (optional) : "
      ERROR_MSG="Error due to non-numeric input. Specify the number of instances to create. The default value is 2 (optional) : "
      SERVER_CONTAINER_GROUP_DESIRED=$(fnReadNumericInput "$INPUT_MSG" "$ERROR_MSG" "2")
      
      # Read the autorecovery details
      #------------------------------------------------
      INPUT_MSG="Enable autorecovery for the MobileFirst Server container instances. Accepted values are Y or N. The default value is N (optional) : "
      ERROR_MSG="Input should be either Y or N. Enable autorecovery for the MobileFirst Server container instances. Accepted values are Y or N. The default value is N (optional) : "
      ENABLE_AUTORECOVERY=$(readBoolean "$INPUT_MSG" "$ERROR_MSG" "N")

      # Read the host name of the route
      #--------------------------------
      INPUT_MSG="Specify the host name of the route (special characters are not allowed) (mandatory) : "
      ERROR_MSG="Host name cannot be empty. Specify the host name of the route (special characters are not allowed) (mandatory) : "
      SERVER_CONTAINER_GROUP_HOST=$(fnReadInput "$INPUT_MSG" "$ERROR_MSG")

      # Read the domain of the route
      #-----------------------------
      INPUT_MSG="Specify the domain of the route (mandatory) : "
      ERROR_MSG="Domain cannot be empty. Specify the domain of the route (mandatory) : "
      SERVER_CONTAINER_GROUP_DOMAIN=$(fnReadInput "$INPUT_MSG" "$ERROR_MSG")

      # Read the Bluemix application name
      #-----------------------------------
      read -p "Specify the Bluemix application name that should be bound to the container (optional) : " APP_NAME

      # Read the memory for the MobileFirst Server container
      #-----------------------------------------------------
      INPUT_MSG="Specify the memory size limit (in MB) for the MobileFirst Server container. Accepted values are 1024, 2048,... The default value is 1024 (optional) : "
      ERROR_MSG="Error due to non-numeric input. Specify a valid value. Valid values are 1024, 2048,... The default value is 1024 MB. (optional) : "
      SERVER_MEM=$(fnReadNumericInput "$INPUT_MSG" "$ERROR_MSG" "1024")

      # Read the Mounting Volume/Trace Spec details
      #------------------------------------------------
      INPUT_MSG="Enable mounting volume for the MobileFirst Server container logs. Accepted values are Y or N. The default value is N (optional) : "
      ERROR_MSG="Input should be either Y or N. Enable mounting volume for the MobileFirst Server container logs. Accepted values are Y or N. The default value is N (optional) : "
      ENABLE_VOLUME=$(readBoolean "$INPUT_MSG" "$ERROR_MSG" "N")
      
      read -p "Provide the Trace specification to be applied to the MobileFirst Server. The default value is *=info (optional) : " TRACE_SPEC

      # Read the maximum number of log files
      #-------------------------------------
      INPUT_MSG="Provide the maximum number of log files to maintain before overwriting them. The default value is 5 files. (optional) : " 
      ERROR_MSG="Error due to non-numeric input. Provide the maximum number of log files to maintain before overwriting them. The default value is 5 files. (optional) : "
      MAX_LOG_FILES=$(fnReadNumericInput "$INPUT_MSG" "$ERROR_MSG" "5")

      # Maximum size of a log file in MB
      #----------------------------------
      INPUT_MSG="Maximum size of a log file (in MB). The default value is 20 MB. (optional): " 
      ERROR_MSG="Error due to non-numeric input. Specify a number to represent the maximum log file size (in MB) allowed. The default value is 20 MB. (optional) : "
      MAX_LOG_FILE_SIZE=$(fnReadNumericInput "$INPUT_MSG" "$ERROR_MSG" "20")

      # Specify the MobileFirst Platform Foundation related properties 
      #---------------------------------------------------------------   
      read -p "Specify related MobileFirst Platform Foundation properties as comma-separated key:value pairs (optional) : " MFPF_PROPERTIES

}

validateParams() 
{

	if [ -z "$SERVER_IMAGE_TAG" ]
	then
    	echo Server Image name is empty. A mandatory argument must be specified. Exiting...
		exit 0
	fi
	
	if [ -z "$SERVER_CONTAINER_GROUP_NAME" ]
	then
   		echo Server Container Group Name is empty. A mandatory argument must be specified. Exiting...
		exit 0
	fi
	
	if [ -z "$SERVER_CONTAINER_GROUP_HOST" ]
	then
   		echo Server Container Group Host is empty. A mandatory argument must be specified. Exiting...
		exit 0
	fi
	
	if [ `expr "$SERVER_CONTAINER_GROUP_HOST" : ".*[!@#\$%^\&*()_+].*"` -gt 0 ];
    then 
    	echo Server Container Group Host name should not contain special characters. Exiting...
		exit 0 
    fi

	if [ -z "$SERVER_CONTAINER_GROUP_DOMAIN" ]
	then
    	echo Server Container Group Domain is empty. A mandatory argument must be specified. Exiting...
		exit 0
	fi

   if [ -z $SERVER_CONTAINER_GROUP_MIN ]
   then 
      SERVER_CONTAINER_GROUP_MIN=1;
   fi

	if [ "$(isNumber $SERVER_CONTAINER_GROUP_MIN)" = "1" ]
    then
        echo  Required Server Container Group Min No. of Instances must be a number. Exiting...
        exit 0
    fi

   if [ -z $SERVER_CONTAINER_GROUP_MAX ]
   then 
		SERVER_CONTAINER_GROUP_MAX=2;
   fi
	
	if [ "$(isNumber $SERVER_CONTAINER_GROUP_MAX)" = "1" ]
    then
        echo  Required Server Container Group Max No. of Instances must be a number. Exiting...
		exit 0
    fi

   if [ -z $SERVER_CONTAINER_GROUP_DESIRED ]
   then 
		SERVER_CONTAINER_GROUP_DESIRED=2;
   fi
	
	if [ "$(isNumber $SERVER_CONTAINER_GROUP_DESIRED)" = "1" ]
    then
        echo Required Server Container Group Desired No. of Instances must be a Number. Exiting...
	    exit 0
    fi
    
    if [ -z "$ENABLE_AUTORECOVERY" ]
   then 
      ENABLE_AUTORECOVERY=N
   fi

	if [ "$(validateBoolean $ENABLE_AUTORECOVERY)" = "1" ]
    then
        echo Invalid value for ENABLE_AUTORECOVERY. Values must either Y / N. Exiting...
	    exit 0
    fi
    
   if [ -z "$SERVER_MEM" ]
   then 
    	SERVER_MEM=1024
   fi

	if [ "$(isNumber $SERVER_MEM)" = "1" ]
    then
        echo  Required Server Container Group memory must be a number. Exiting...
	    exit 0
    fi

   if [ -z "$ENABLE_VOLUME" ]
   then 
      ENABLE_VOLUME=N
   fi

	if [ "$(validateBoolean $ENABLE_VOLUME)" = "1" ]
    then
        echo  "Invalid value for ENABLE_VOLUME. Values must either Y / N. Exiting..."
	    exit 0
    fi
   
   if [ -z "$EXPOSE_HTTP" ]
   then 
      EXPOSE_HTTP=Y
   fi

	if [ "$(validateBoolean $EXPOSE_HTTP)" = "1" ]
    then
        echo  "Invalid value for EXPOSE_HTTP. Values must either Y / N. Exiting..."
	    exit 0
    fi

   if [ -z "$EXPOSE_HTTPS" ]
   then 
      EXPOSE_HTTPS=Y
   fi 

	if [ "$(validateBoolean $EXPOSE_HTTPS)" = "1" ]
    then
        echo  "Invalid value for EXPOSE_HTTPS. Values must either Y / N. Exiting..."
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
         -gn | --name)
            SERVER_CONTAINER_GROUP_NAME="$2";
            shift
            ;;
         -gm | --min)
            SERVER_CONTAINER_GROUP_MIN="$2";
            shift
            ;;
         -gx | --max)
            SERVER_CONTAINER_GROUP_MAX="$2";
            shift
            ;;
         -gd | --desired)
            SERVER_CONTAINER_GROUP_DESIRED="$2";
            shift
            ;;
         -a | --auto)
            ENABLE_AUTORECOVERY="$2";
            shift
            ;;
         -gh | --host)
            SERVER_CONTAINER_GROUP_HOST="$2";
            shift
            ;;
         -gs | --domain)
            SERVER_CONTAINER_GROUP_DOMAIN="$2";
            shift
            ;;
         -m | --memory)
            SERVER_MEM="$2";
            shift
            ;;
         -an | --appName)
            APP_NAME="$2";
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
         -p | --https)
            EXPOSE_HTTPS="$2";
            shift
            ;;
         -e | --env)
            MFPF_PROPERTIES="$2";
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
echo "SERVER_CONTAINER_GROUP_NAME : " $SERVER_CONTAINER_GROUP_NAME
echo "SERVER_CONTAINER_GROUP_HOST : " $SERVER_CONTAINER_GROUP_HOST
echo "SERVER_CONTAINER_GROUP_DOMAIN : " $SERVER_CONTAINER_GROUP_DOMAIN
echo "SERVER_CONTAINER_GROUP_MIN : " $SERVER_CONTAINER_GROUP_MIN
echo "SERVER_CONTAINER_GROUP_MAX : " $SERVER_CONTAINER_GROUP_MAX
echo "SERVER_CONTAINER_GROUP_DESIRED : " $SERVER_CONTAINER_GROUP_DESIRED
echo "ENABLE_AUTORECOVERY : " $ENABLE_AUTORECOVERY
echo "APP_NAME : " $APP_NAME
echo "SERVER_MEM : " $SERVER_MEM
echo "TRACE_SPEC : " $TRACE_SPEC
echo "MAX_LOG_FILES : " $MAX_LOG_FILES
echo "MAX_LOG_FILE_SIZE : " $MAX_LOG_FILE_SIZE
echo "ENABLE_VOLUME : " $ENABLE_VOLUME
echo "MFPF_PROPERTIES : " $MFPF_PROPERTIES
echo

cmd="cf ic group create --name $SERVER_CONTAINER_GROUP_NAME -n $SERVER_CONTAINER_GROUP_HOST -d $SERVER_CONTAINER_GROUP_DOMAIN -m $SERVER_MEM -e MFPF_CLUSTER_MODE=Farm --min $SERVER_CONTAINER_GROUP_MIN --max $SERVER_CONTAINER_GROUP_MAX --desired $SERVER_CONTAINER_GROUP_DESIRED"

if [ "$ENABLE_AUTORECOVERY" = "Y" ] || [ "$ENABLE_AUTORECOVERY" = "y" ]
then
   cmd="$cmd --auto"
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
   cmd="$cmd -p $MFPF_SERVER_HTTPPORT"
fi

if [ ! -z "$APP_NAME" ]
then 
   cmd="$cmd -e CCS_BIND_APP=$APP_NAME"
fi

default_mfpf_properties="publicWorkLightHostname:"$SERVER_CONTAINER_GROUP_HOST"."$SERVER_CONTAINER_GROUP_DOMAIN",publicWorkLightPort:80,publicWorkLightProtocol:http"

if [ ! -z "$MFPF_PROPERTIES" ]
then
    MFPF_PROPERTIES=$MFPF_PROPERTIES","$default_mfpf_properties
 else
    MFPF_PROPERTIES=$default_mfpf_properties   
fi

cmd="$cmd -e mfpfproperties=$MFPF_PROPERTIES"

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

cmd="$cmd $SERVER_IMAGE_TAG"
echo "Starting the MobileFirst Server container group : " $SERVER_CONTAINER_GROUP_NAME
echo "Executing command : " $cmd

CMD_RUN_RESULT=`eval ${cmd};`
echo
echo "$CMD_RUN_RESULT"

GREPPED_RESULT=$(echo $CMD_RUN_RESULT | grep -i "Error" | wc -l | tr -s " ")

if [ $(echo $GREPPED_RESULT) != "0" ]
then
    echo "ERROR: cf ic group create command failed. Exiting ..."
    exit 1
fi

CREATE_STATUS=$(echo $CMD_RUN_RESULT | grep -i "Created group $SERVER_CONTAINER_GROUP_NAME" | wc -l | tr -s " ")
if [ $(echo $CREATE_STATUS) != "0" ]
then
    SERVER_CONTAINER_GROUP_ID=$(echo $CMD_RUN_RESULT | sed -e 's/.*(id:\(.*\)).*/\1/' | tr -d " ")
else 
    echo "ERROR: cf ic group create command failed. Exiting ..."
    exit 1
fi


sleep 5s
echo "Checking the status of the Container Group - $SERVER_CONTAINER_GROUP_NAME (id: $SERVER_CONTAINER_GROUP_ID) ..."
COUNTER=40
while [ $COUNTER -gt 0 ]
do
    CONTAINER_GROUP_LIST=`eval cf ic group inspect $SERVER_CONTAINER_GROUP_ID`
    CONTAINER_RUN_STATE=$(echo $CONTAINER_GROUP_LIST | grep $SERVER_CONTAINER_GROUP_ID | grep '"Status": "CREATE_COMPLETE"' | wc -l )
    if [ $(echo $CONTAINER_RUN_STATE) = "1" ]
	then
        echo "Container group has been created successfully and is in CREATE_COMPLETE state"
        echo 
		break
	fi

    if [ $(echo $CONTAINER_GROUP_LIST | grep $SERVER_CONTAINER_GROUP_ID | grep -Ei '"Status": "CREATE_FAILED"' | wc -l) = "1" ]
    then
		echo "ERROR: cf ic container group is in CREATE_FAILED status. Exiting ..."
		exit 1
    fi
    
	# Allow to container group to come up
	sleep 5s

    COUNTER=`expr $COUNTER - 1`
done

echo "Checking the status of the Route mapping to the Container group ..."

COUNTER=40
while [ $COUNTER -gt 0 ]
do
    CONTAINER_IP_STATE=$(echo $(cf ic group inspect $SERVER_CONTAINER_GROUP_ID | grep '"successful": true' | wc -l ))
    if [ $CONTAINER_IP_STATE -ge 1 ]
    then
        echo "Mapping the MobileFirst Server container group to Host : " $SERVER_CONTAINER_GROUP_HOST ", Domain : " $SERVER_CONTAINER_GROUP_DOMAIN " is successful"
        echo 
        break
    fi

    # Allow to container group to come up
    sleep 5s

    COUNTER=`expr $COUNTER - 1`
done

echo "Detailed Status of the container group and the mapping can be verified using the following cf ic command"
echo "        cf ic group inspect $SERVER_CONTAINER_GROUP_ID"
echo ""

