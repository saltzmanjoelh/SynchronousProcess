#!/bin/sh

#  ExternalBuild.sh
#
#  Created by Joel Saltzman on 7/14/16.
#  Used with External Build Target to get linux build errors to appear in xcode
#  MAKE SURE THAT THIS FILE IS EXECUTABLE - chmod +x ExternalBuild.sh


#DOCKER_IMAGE = saltzmanjoelh/swiftubuntu
#AWS_CLI = /usr/local/bin/aws
#S3_BUCKET_ROOT = projname (upload the archive to S3_BUCKET_ROOT.BRANCH_NAME, ie projname.develop)

#LOG_FILE=null
LOG_FILE="/Users/Shared/$PROJECT.txt"

if [ -z "$DOCKER_IMAGE" ]; then DOCKER_IMAGE="saltzmanjoelh/swiftubuntu"; fi;

#Since the ExternalBuild Target uses a different TARGET_NAME from the source project, we assume that we a building something with the same name as the project's name
#if that is not the case, you can specify a User Defined Build Setting BUILT_PRODUCT_NAME=MySwiftTargetName
if [ -z "$BUILT_PRODUCT_NAME" ]; then BUILT_PRODUCT_NAME=$PROJECT; fi;
echo "Building $BUILT_PRODUCT_NAME" > $LOG_FILE 2>&1

if [ -z "$DOCKER_CONTAINER_NAME" ]; then DOCKER_CONTAINER_NAME=$PROJECT; fi;
echo "Container Name: $DOCKER_CONTAINER_NAME" > $LOG_FILE 2>&1

#if [ $ACTION == 'clean' ]; then #If cleaning, delete it
#docker rm -v $DOCKER_CONTAINER_NAME;
#fi

#We use some default build commands. If it's in release mode, we archive the built product and copy into the source directory.
#If you want to do something different, create a User Defined Build Setting (DOCKER_COMMAND=echo 'do something') that will be passed to docker via /bin/bash -c "$DOCKER_COMMAND"
BUILD_CONFIGURATION=$(echo "$CONFIGURATION" | tr [:upper:] [:lower:])
echo "BUILD_CONFIGURATION ${BUILD_CONFIGURATION} ACTION ${ACTION}"
cd $PROJECT_DIR
BRANCH_NAME=`git branch | grep -e "^*" | cut -d' ' -f 2`
S3_ARCHIVE_NAME="${BUILT_PRODUCT_NAME}.tar"

#Build
if [ -z "$DOCKER_COMMAND" ]; then
DOCKER_COMMAND="cd $PROJECT_DIR;"; DOCKER_COMMAND+=$'\n';#move to project dir
DOCKER_COMMAND+=$'if [ -d .build ]; then swift build --clean; fi;' # clean the old build directory if it's there
DOCKER_COMMAND+="swift build -c ${BUILD_CONFIGURATION};"; DOCKER_COMMAND+=$'\n' #match the linux build configuration with the xcode project configuration
#Archive and Upload
DOCKER_COMMAND+="if [ \"${ACTION}\" == \"install\" ]; then " #if in release mode, archive the product
DOCKER_COMMAND+=$'BUILT_TARGET=""\n'
DOCKER_COMMAND+="if   [ -f \".build/${BUILD_CONFIGURATION}/${BUILT_PRODUCT_NAME}\" ]; then BUILT_TARGET=\"${BUILT_PRODUCT_NAME}\""; DOCKER_COMMAND+=$'\n'
DOCKER_COMMAND+="elif [ -f \".build/${BUILD_CONFIGURATION}/${BUILT_PRODUCT_NAME}.swiftmodule\" ]; then BUILT_TARGET=\"${BUILT_PRODUCT_NAME}.swiftmodule\""; DOCKER_COMMAND+=$'\n'
DOCKER_COMMAND+=$'else echo "Failed to find a built product"; ls -al\n'
DOCKER_COMMAND+=$'fi\n'
#archive
DOCKER_COMMAND+="echo \"tarring executable\"; tar -cvzf \"${S3_ARCHIVE_NAME}\" Dockerfile ssl -C .build/${BUILD_CONFIGURATION} ";DOCKER_COMMAND+=$'$BUILT_TARGET\n'
DOCKER_COMMAND+=$'fi\n'
fi

if [ -z "$DOCKER_TOOLBOX" ]; then DOCKER_TOOLBOX=1; fi;
echo "TOOLBOX $DOCKER_TOOLBOX"
if [ $DOCKER_TOOLBOX -eq 1 ]; then
#configure vars
VM=default
DOCKER_MACHINE=/usr/local/bin/docker-machine
VBOXMANAGE=/Applications/VirtualBox.app/Contents/MacOS/VBoxManage
unset DYLD_LIBRARY_PATH
unset LD_LIBRARY_PATH

#verify apps exist
if [ ! -f $DOCKER_MACHINE ] || [ ! -f $VBOXMANAGE ]; then
echo "Either VirtualBox or Docker Machine are not installed. Please re-run the Toolbox Installer and try again." >> $LOG_FILE 2>&1
exit 1
fi
#verify vm exists
$VBOXMANAGE showvminfo $VM &> /dev/null
VM_EXISTS_CODE=$?



#create and start if needed
if [ $VM_EXISTS_CODE -eq 1 ]; then
echo "Creating Machine $VM..." >> $LOG_FILE 2>&1
$DOCKER_MACHINE rm -f $VM &> /dev/null
rm -rf ~/.docker/machine/machines/$VM
$DOCKER_MACHINE create -d virtualbox --virtualbox-memory 2048 $VM
else
echo "Machine $VM already exists in VirtualBox." >> $LOG_FILE 2>&1
fi
echo "Starting machine $VM..." >> $LOG_FILE 2>&1
$DOCKER_MACHINE start $VM

#prepare docker
echo "Machine started, logging in." >> $LOG_FILE 2>&1
eval "$(docker-machine env --shell=bash default)" > $LOG_FILE 2>&1
bash --login >> $LOG_FILE 2>&1
echo "Logged in, starting image ${DOCKER_IMAGE} and running \"$DOCKER_COMMAND\"" >> $LOG_FILE 2>&1
fi

#delete existing container with same name
DOCKER_ACTION="run -v $PROJECT_DIR:$PROJECT_DIR --name $DOCKER_CONTAINER_NAME"
PS_RESULT=`docker ps -a | grep "$DOCKER_CONTAINER_NAME" | wc -m`
if [ $PS_RESULT -gt 0 ]; then docker rm -v $DOCKER_CONTAINER_NAME ; fi #if container exists, exec instead of run


#start container
docker $DOCKER_ACTION $DOCKER_IMAGE /bin/bash -c "$DOCKER_COMMAND" # don't redirect output, xcode will handle it for you >> $LOG_FILE 2>&1


#upload archive from osx
if [ "${ACTION}" == "install" ]; then
    cd $PROJECT_DIR
    if [ -f "${S3_ARCHIVE_NAME}" ]; then
        $AWS_CLI s3 cp "${S3_ARCHIVE_NAME}" "s3://${S3_BUCKET_ROOT}.${BRANCH_NAME}/${S3_ARCHIVE_NAME}"
        rm "${S3_ARCHIVE_NAME}"
    else echo "Archive (${S3_ARCHIVE_NAME}) not found."; ls -al
    fi
fi

echo "Done" >> $LOG_FILE 2>&1
