#   Licensed Materials - Property of IBM 
#   5725-I43 (C) Copyright IBM Corp. 2011, 2015. All Rights Reserved.
#   US Government Users Restricted Rights - Use, duplication or
#   disclosure restricted by GSA ADP Schedule Contract with IBM Corp.  
   
#!/usr/bin/bash

usage() 
{
   echo 
   echo " Running the MobileFirst Operational Analytics Image as a Container Group "
   echo " ---------------------------------------------------------------------------------- "
   echo " Use this script to run the MobileFirst Operational Analytics"
   echo " image as a container group on the IBM Containers service on Bluemix."
   echo " Prerequisite: The prepareanalytics.sh script must be run before running this script."
   echo
   echo " Silent Execution (arguments provided as command line arguments): "
   echo "   USAGE: startanalyticsgroup.sh <command line arguments> "
   echo "   command-line arguments: "
   echo "     -t | --tag ANALYTICS_IMAGE_TAG                    The name of the analytics image"
   echo "     -gn | --name ANALYTICS_CONTAINER_GROUP_NAME       The name of the analytics container group"
   echo "     -gh | --host ANALYTICS_CONTAINER_GROUP_HOST       The host name of the route"
   echo "     -gs | --domain ANALYTICS_CONTAINER_GROUP_DOMAIN   The domain name of the route"
   echo "     -gm | --min ANALYTICS_CONTAINER_GROUP_MIN         (Optional) The minimum number of instances. The default value is 1"
   echo "     -gx | --max ANALYTICS_CONTAINER_GROUP_MAX         (Optional) The maximum number of instances. The default value is 2"
   echo "     -gd | --desired ANALYTICS_CONTAINER_GROUP_DESIRED (Optional) The desired number of instances. The default value is 2"   
   echo "     -a  | --auto ENABLE_AUTORECOVERY                Enable Auto-recovery option for the container instances. The default is N"
   echo "     -tr | --trace TRACE_SPEC             (Optional) Trace specification to be applied to MobileFirst Server"
   echo "     -ml | --maxlog MAX_LOG_FILES         (Optional) Maximum number of log files to maintain before overwriting"
   echo "     -ms | --maxlogsize MAX_LOG_FILE_SIZE (Optional) Maximum size of a log file"
   echo "     -e | --env MFPF_PROPERTIES           (Optional) MFP Analytics related properties as comma separated key:value pairs"
   echo "     -m | --memory SERVER_MEM             (Optional) Assign a memory limit to the container in MB. Accepted values"
   echo "                                            are 1024 (default), 2048,..."
   echo "     -v | --volume ENABLE_VOLUME              (Optional) Enable mounting volume for the container logs. Accepted values are Y (default) or N"
   echo "     -ev | --enabledatavolume ENABLE_ANALYTICS_DATA_VOLUME       (Optional) Enable mounting volume for analytics data. Accepted values are Y or N (default)"
   echo "     -av | --datavolumename ANALYTICS_DATA_VOLUME_NAME           (Optional) Specify name of the volume to be created and mounted for analytics data. Default value is mfpf_analytics_<ANALYTICS_CONTAINER_GROUP_NAME>"
   echo "     -ad | --analyticsdatadirectory ANALYTICS_DATA_DIRECTORY     (Optional) Specify the directory to be used for storing analytics data. Default value is /analyticsData"
   echo 
   echo " Silent Execution (arguments loaded from file): "
   echo "   USAGE: startanalyticsgroup.sh <path to the file from which arguments are read>"
   echo "          See args/startanalyticsgroup.properties for the list of arguments."
   echo 
   echo " Interactive Execution: "
   echo "   USAGE: startanalyticsgroup.sh"
   echo
   exit 1
}

readParams()
{

	# Read the name of the MobileFirst Operational Analytics image
	#-------------------------------------------------------------
	INPUT_MSG="Specify the name of the analytics image. Should be of form registryUrl/repositoryNamespace/imagename (mandatory) : "
	ERROR_MSG="Name of the analytics image cannot be empty. Specify the name for the analytics image. Should be of form registryUrl/repositoryNamespace/imagename (mandatory) : " 
	ANALYTICS_IMAGE_TAG=$(fnReadInput "$INPUT_MSG" "$ERROR_MSG")

	# Read the name of the MobileFirst Operational Analytics container group
	#-----------------------------------------------------------------------
	INPUT_MSG="Specify the name for the analytics container group (mandatory) : "
	ERROR_MSG="Container group name cannot be empty. Specify the name for the analytics container group (mandatory) : "
	ANALYTICS_CONTAINER_GROUP_NAME=$(fnReadInput "$INPUT_MSG" "$ERROR_MSG")
	
	# Read the minimum number of instances
	#-------------------------------------
	INPUT_MSG="Specify the minimum number of instances. The default value is 1 (optional) : "
	ERROR_MSG="Error due to non-numeric input. Specify the minimum number of instances. The default value is 1 (optional) : "
	ANALYTICS_CONTAINER_GROUP_MIN=$(fnReadNumericInput "$INPUT_MSG" "$ERROR_MSG" "1")
	
	# Read the maximum number of instances
	#-------------------------------------
	INPUT_MSG="Specify the maximum number of instances. The default value is 2 (optional) : " 
	ERROR_MSG="Error due to non-numeric input. Specify the maximum number of instances. The default value is 2 (optional) : " 
	ANALYTICS_CONTAINER_GROUP_MAX=$(fnReadNumericInput "$INPUT_MSG" "$ERROR_MSG" "2")
	
	# Read the desired number of instances
	#-------------------------------------
	INPUT_MSG="Specify the desired number of instances. The default value is 2 (optional) : "
	ERROR_MSG="Error due to non-numeric input. Specify the desired number of instances. The default value is 2 (optional) : "
	ANALYTICS_CONTAINER_GROUP_DESIRED=$(fnReadNumericInput "$INPUT_MSG" "$ERROR_MSG" "2")            

	# Read the autorecovery details
	#------------------------------------------------
	INPUT_MSG="Enable autorecovery for the MobileFirst Server container instances. Accepted values are Y or N. The default value is N (optional) : "
	ERROR_MSG="Input should be either Y or N. Enable autorecovery for the MobileFirst Server container instances. Accepted values are Y or N. The default value is N (optional) : "
	ENABLE_AUTORECOVERY=$(readBoolean "$INPUT_MSG" "$ERROR_MSG" "N")

	# Read the host name of the route
	#--------------------------------
	INPUT_MSG="Specify the host name of the route (special characters are not allowed) (mandatory) : "
	ERROR_MSG="Host name cannot be empty. Specify the host name of the route (special characters are not allowed) (mandatory) : "
	ANALYTICS_CONTAINER_GROUP_HOST=$(fnReadInput "$INPUT_MSG" "$ERROR_MSG")
	
	# Read the domain of the route
	#-----------------------------
	INPUT_MSG="Specify the domain of the route (mandatory) : "
	ERROR_MSG="Domain cannot be empty. Specify the domain of the route (mandatory) : "
	ANALYTICS_CONTAINER_GROUP_DOMAIN=$(fnReadInput "$INPUT_MSG" "$ERROR_MSG")
   
	# Read the memory for the Analytics container
	#--------------------------------------------
	INPUT_MSG="Specify the memory size limit (in MB) for the analytics container. Accepted values are 1024, 2048,... The default value is 1024 MB (optional) : "
	ERROR_MSG="Error due to non-numeric input. Specify a valid value. Valid values are 1024, 2048,... The default value is 1024 MB. (optional) : "
	SERVER_MEM=$(fnReadNumericInput "$INPUT_MSG" "$ERROR_MSG" "1024")
 
	# Read the mount volume details 
	#----------------------------------------
   
	INPUT_MSG="Enable mounting volume for the analytics container logs. Accepted values are Y or N. The default value is N (optional) : "
	ERROR_MSG="Input should be either Y or N. Enable mounting volume for the analytics container logs. Accepted values are Y or N. The default value is N (optional) : "
	ENABLE_VOLUME=$(readBoolean "$INPUT_MSG" "$ERROR_MSG" "N")
  
	# Read the analytics data volume details 
	#----------------------------------------
   
   INPUT_MSG="Enable mounting volume for analytics data. Accepted values are Y or N. The default value is N (optional) : "
   ERROR_MSG="Input should be either Y or N. Enable mounting volume for analytics data. Accepted values are Y or N. The default value is N (optional) : "
   ENABLE_ANALYTICS_DATA_VOLUME=$(readBoolean "$INPUT_MSG" "$ERROR_MSG" "N")

   if [ "$ENABLE_ANALYTICS_DATA_VOLUME" = "Y" ] || [ "$ENABLE_ANALYTICS_DATA_VOLUME" = "y" ]
   then   
       read -p "Specify name of the volume to be created and mounted for analytics data. Default value is mfpf_analytics_<ANALYTICS_CONTAINER_GROUP_NAME> (optional) : " ANALYTICS_DATA_VOLUME_NAME
   fi
   read -p "Specify the directory to be used for storing analytics data. Default value is /analyticsData (optional) : " ANALYTICS_DATA_DIRECTORY
   
   # Read the trace details 
   #---------------------
   
   read -p "Provide the Trace specification to be applied to the MobileFirst Analytics. The default value is *=info (optional): " TRACE_SPEC
  
   # Read the maximum number of log files
   #-------------------------------------
   INPUT_MSG="Provide the maximum number of log files to maintain before overwriting them. The default value is 5 (optional): "
   ERROR_MSG="Error due to non-numeric input. Provide the maximum number of log files to maintain before overwriting them. The default value is 5 (optional): " 
   MAX_LOG_FILES=$(fnReadNumericInput "$INPUT_MSG" "$ERROR_MSG" "5")

   # Maximum size of a log file in MB
   #----------------------------------
   INPUT_MSG="Maximum size of a log file in MB. The default value is 20 (optional): "
   ERROR_MSG="Error due to non-numeric input. Specify the maximum size of a log file in MB. The default value is 20 (optional): " 
   MAX_LOG_FILE_SIZE=$(fnReadNumericInput "$INPUT_MSG" "$ERROR_MSG" "20")

   # Specify the related MobileFirst Platform Foundation properties 
   #---------------------------------------------------------------   
	read -p "Specify the MobileFirst Operational Analytics related properties as comma separated key:value pairs (optional) : " MFPF_PROPERTIES

}

validateParams() 
{
 	if [ -z "$ANALYTICS_IMAGE_TAG" ]
	then
    	echo Analytics Image Name is empty. A mandatory argument must be specified. Exiting...
		exit 0
	fi
	
	if [ -z "$ANALYTICS_CONTAINER_GROUP_NAME" ]
	then
   		echo Analytics Container Group Name is empty. A mandatory argument must be specified. Exiting...
		exit 0
	fi
	
	if [ -z "$ANALYTICS_CONTAINER_GROUP_HOST" ]
	then
   		echo Analytics Container Group Host is empty. A mandatory argument must be specified. Exiting...
		exit 0
	fi
	
	if [ `expr "$ANALYTICS_CONTAINER_GROUP_HOST" : ".*[!@#\$%^\&*()_+].*"` -gt 0 ]
    then 
       	echo Analytics Container Group Host name should not contain special characters. Exiting...
		exit 0 
    fi

	if [ -z "$ANALYTICS_CONTAINER_GROUP_DOMAIN" ]
	then
    	echo Analytics Container Group Domain is empty. A mandatory argument must be specified. Exiting...
		exit 0
	fi

	if [ -z "$ANALYTICS_HTTPPORT" ]
	then
    	echo ANALYTICS_HTTPPORT is empty. A mandatory argument must be specified. Exiting...
		exit 0
	fi
	
	if [ -z "$ANALYTICS_HTTPSPORT" ]
	then
    	echo ANALYTICS_HTTPSPORT is empty. A mandatory argument must be specified. Exiting...
		exit 0
	fi

	if [ -z $ANALYTICS_CONTAINER_GROUP_MIN ]
	then 
		ANALYTICS_CONTAINER_GROUP_MIN=1;
	fi

	if [ "$(isNumber $ANALYTICS_CONTAINER_GROUP_MIN)" = "1" ]
    then
		echo  Required Analytics Container Group Min No. of Instances must be a Number. Exiting...
		exit 0
    fi

	if [ -z $ANALYTICS_CONTAINER_GROUP_MAX ]
	then 
		ANALYTICS_CONTAINER_GROUP_MAX=2;
	fi

	if [ "$(isNumber $ANALYTICS_CONTAINER_GROUP_MAX)" = "1" ]
	then
		echo  Required Analytics Container Group Max No. of Instances must be a Number. Exiting...
		exit 0
    fi

	if [ -z $ANALYTICS_CONTAINER_GROUP_DESIRED ]
	then 
		ANALYTICS_CONTAINER_GROUP_DESIRED=2;
	fi
	
	if [ "$(isNumber $ANALYTICS_CONTAINER_GROUP_DESIRED)" = "1" ]
	then
		echo  Required Analytics Container Group Desired No. of Instances must be a Number. Exiting...
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
        echo  Required Analytics Container Group Memory must be a Number. Exiting...
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
        echo  Invalid Value for ENABLE_VOLUME. Values must be either Y / N. Exiting...
	    exit 0
    fi
   
	if [ -z "$ANALYTICS_DATA_VOLUME_NAME" ]
	then
		ANALYTICS_DATA_VOLUME_NAME=mfpf_analytics_$ANALYTICS_CONTAINER_GROUP_NAME
	fi   
    
	if [ -z "$ANALYTICS_DATA_DIRECTORY" ]
	then
		ANALYTICS_DATA_DIRECTORY=/analyticsData
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
         -gn | --name)
            ANALYTICS_CONTAINER_GROUP_NAME="$2";
            shift
            ;;
         -gm | --min)
            ANALYTICS_CONTAINER_GROUP_MIN="$2";
            shift
            ;;
         -gx | --max)
            ANALYTICS_CONTAINER_GROUP_MAX="$2";
            shift
            ;;
         -gd | --desired)
            ANALYTICS_CONTAINER_GROUP_DESIRED="$2";
            shift
            ;;
         -a | --auto)
            ENABLE_AUTORECOVERY="$2";
            shift
            ;;
         -gh | --host)
            ANALYTICS_CONTAINER_GROUP_HOST="$2";
            shift
            ;;
         -gs | --domain)
            ANALYTICS_CONTAINER_GROUP_DOMAIN="$2";
            shift
            ;;
         -m | --memory)
            SERVER_MEM="$2";
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
         -e | --env)
            MFPF_PROPERTIES="$2";
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
echo "ANALYTICS_CONTAINER_GROUP_NAME : " $ANALYTICS_CONTAINER_GROUP_NAME
echo "ANALYTICS_CONTAINER_GROUP_MIN : " $ANALYTICS_CONTAINER_GROUP_MIN
echo "ANALYTICS_CONTAINER_GROUP_MAX : " $ANALYTICS_CONTAINER_GROUP_MAX
echo "ANALYTICS_CONTAINER_GROUP_DESIRED : " $ANALYTICS_CONTAINER_GROUP_DESIRED
echo "ENABLE_AUTORECOVERY : " $ENABLE_AUTORECOVERY
echo "ANALYTICS_CONTAINER_GROUP_HOST : " $ANALYTICS_CONTAINER_GROUP_HOST
echo "ANALYTICS_CONTAINER_GROUP_DOMAIN : " $ANALYTICS_CONTAINER_GROUP_DOMAIN
echo "SERVER_MEM : " $SERVER_MEM
echo "TRACE_SPEC : " $TRACE_SPEC
echo "MAX_LOG_FILES : " $MAX_LOG_FILES
echo "MAX_LOG_FILE_SIZE : " $MAX_LOG_FILE_SIZE
echo "MFPF_PROPERTIES : " $MFPF_PROPERTIES
echo "ENABLE_VOLUME : " $ENABLE_VOLUME
echo "ENABLE_ANALYTICS_DATA_VOLUME : " $ENABLE_ANALYTICS_DATA_VOLUME
echo "ANALYTICS_DATA_VOLUME_NAME : " $ANALYTICS_DATA_VOLUME_NAME
echo "ANALYTICS_DATA_DIRECTORY : " $ANALYTICS_DATA_DIRECTORY
echo

ANALYTICS_COMM_PORT=9600
ANALYTICS_DEBUG_PORT=9500

cmd="cf ic group create --name $ANALYTICS_CONTAINER_GROUP_NAME -n $ANALYTICS_CONTAINER_GROUP_HOST -d $ANALYTICS_CONTAINER_GROUP_DOMAIN -m $SERVER_MEM --min $ANALYTICS_CONTAINER_GROUP_MIN --max $ANALYTICS_CONTAINER_GROUP_MAX --desired $ANALYTICS_CONTAINER_GROUP_DESIRED -p $ANALYTICS_HTTPPORT"

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

if [ "$ENABLE_ANALYTICS_DATA_VOLUME" = "Y" ] || [ "$ENABLE_ANALYTICS_DATA_VOLUME" = "y" ]
then
	createDataVolume
	cmd="$cmd -v $ANALYTICS_DATA_VOLUME_NAME:$ANALYTICS_DATA_DIRECTORY -e ANALYTICS_DATA_DIRECTORY=$ANALYTICS_DATA_DIRECTORY"
else 
	cmd="$cmd -e ANALYTICS_DATA_DIRECTORY=$ANALYTICS_DATA_DIRECTORY"   
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

cmd="$cmd -e ANALYTICS_TRACE_LEVEL=$TRACE_SPEC -e ANALYTICS_MAX_LOG_FILES=$MAX_LOG_FILES -e ANALYTICS_MAX_LOG_FILE_SIZE=$MAX_LOG_FILE_SIZE"
cmd="$cmd $ANALYTICS_IMAGE_TAG"

echo "Starting the analytics container group : " $ANALYTICS_CONTAINER_GROUP_NAME
echo "Executing command : " $cmd

CMD_RUN_RESULT=`eval ${cmd}`
echo "$CMD_RUN_RESULT"

GREPPED_RESULT=$(echo $CMD_RUN_RESULT | grep -i "Error" | wc -l | tr -s " ")

if [ $(echo $GREPPED_RESULT) != "0" ]
then
    echo "ERROR: cf ic group create command failed. Exiting ..."
    exit 1
fi
CREATE_STATUS=$(echo $CMD_RUN_RESULT | grep -i "Created group $ANALYTICS_CONTAINER_GROUP_NAME" | wc -l | tr -s " ")
if [ $(echo $CREATE_STATUS) != "0" ]
then
    ANALYTICS_CONTAINER_GROUP_ID=$(echo $CMD_RUN_RESULT | sed -e 's/.*(id:\(.*\)).*/\1/' | tr -d " ")
else 
    echo "ERROR: cf ic group create command failed. Exiting ..."
    exit 1
fi


sleep 5s
echo 
echo "Checking the status of the Container Group - $ANALYTICS_CONTAINER_GROUP_NAME (id: $ANALYTICS_CONTAINER_GROUP_ID) ..."
COUNTER=40
while [ $COUNTER -gt 0 ]
do
    CONTAINER_GROUP_LIST=`eval cf ic group inspect $ANALYTICS_CONTAINER_GROUP_ID`
    CONTAINER_RUN_STATE=$(echo $CONTAINER_GROUP_LIST | grep $ANALYTICS_CONTAINER_GROUP_ID | grep '"Status": "CREATE_COMPLETE"' | wc -l )
    if [ $(echo $CONTAINER_RUN_STATE) = "1" ]
	then
        echo "Container group has been created successfully and is in CREATE_COMPLETE state"
        echo 
		break
	fi

    if [ $(echo $CONTAINER_GROUP_LIST | grep $ANALYTICS_CONTAINER_GROUP_ID | grep '"Status": "CREATE_FAILED"' | wc -l) = "1" ]
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
    CONTAINER_IP_STATE=$(echo $(cf ic group inspect $ANALYTICS_CONTAINER_GROUP_ID | grep '"successful": true' | wc -l ))
    if [ $CONTAINER_IP_STATE -ge 1 ]
    then
        echo "Mapping the MobileFirst Server container group to Host : $ANALYTICS_CONTAINER_GROUP_HOST , Domain : $ANALYTICS_CONTAINER_GROUP_DOMAIN is successful"
        echo 
        break
    fi

    # Allow to container group to come up
    sleep 5s

    COUNTER=`expr $COUNTER - 1`
done

echo "Detailed Status of the container group and the mapping can be verified using the following cf ic command"
echo "        cf ic group inspect $ANALYTICS_CONTAINER_GROUP_ID"
echo 

