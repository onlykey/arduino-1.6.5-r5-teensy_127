#!/bin/bash -xe




branch=$1

if [ "${branch}" == "" ] ; then
    echo "NO BRANCH SELECTED - SETTING TO: MASTER"
    branch="master"
fi


github_fork=$2

if [ "${github_fork}" == "" ] ; then
    github_fork="trustcrypto"
fi

if [ "${branch}" == "local" ] ; then
    firmware_git_path=/onlykey/OnlyKey-Firmware
    libraries_git_path=/onlykey/libraries
    firmware_branch=master
    libraries_branch=master
else
    firmware_git_path=https://github.com/$github_fork/OnlyKey-Firmware
    libraries_git_path=https://github.com/$github_fork/libraries
    firmware_branch=$branch
    libraries_branch=$branch
fi


if [ "${branch}" == "v0.2-beta.8" ] ; then
    firmware_file=OnlyKey_Beta/OnlyKey_Beta.ino
else
    firmware_file=OnlyKey/OnlyKey.ino
fi

# PLEASE NOTE. 
# Most people wont need the ability to compile firmware themselves, 
# as you can't load custom firmware unless you have a developer onlykey.
# Right now you can compile it if you want, but probably not worth your time lol
# 

#https://github.com/trustcrypto/OnlyKey-Firmware/issues/59

####-------   WHERE 
#firmware_git_path=https://github.com/trustcrypto/OnlyKey-Firmware
#libraries_git_path=https://github.com/trustcrypto/libraries

## `/onlykey/.` is relative to this script
## folders, this script is `/onlykey/in-docker-build.sh`, OnlyKey-Firmware, libraries are .gitignored
#firmware_git_path=/onlykey/OnlyKey-Firmware
#libraries_git_path=/onlykey/libraries


####-------   WHAT   ## you can load any git checkouts or branch
#firmware_file=OnlyKey/OnlyKey.ino
#firmware_branch=master
#libraries_branch=master

#firmware_file=OnlyKey_Beta/OnlyKey_Beta.ino
#firmware_branch=v0.2-beta.8
#libraries_branch=v0.2-beta.8


##this builds the arduino folder
##get arduino-ide
#curl https://downloads.arduino.cc/arduino-1.6.5-r5-linux64.tar.xz -o arduino.tar.xz
##get teensyduino
#curl https://www.pjrc.com/teensy/td_127/teensyduino.64bit -o teensyduino
#tar -xvf arduino.tar.xz
#chmod +x teensyduino
#./teensyduino
##old teensy dont work well, so we get the latest
#cd arduino-1.6.5-r5/hardware/tools
#curl https://www.pjrc.com/teensy/teensy_linux64.tar.gz -o teensy_linux64.tar.gz
#rm ./teensy
#tar -xvf teensy_linux64.tar.gz
#rm teensy_linux64.tar.gz
##because we are headless we dont need to open the flasher so dummy the cmd
#mv teensy_post_compile teensy_post_compile_orig
#touch teensy_post_compile
#chmod +x teensy_post_compile
#cd ../../..


cd /builds
# rm -rf /builds/* #clean last build

rm -rf /builds/arduino-1.6.5-r5*
#get clean arduino
cp -a /onlykey/arduino-1.6.5-r5 /builds/.

rm -rf /builds/OnlyKey-Firmware
#get firmware
if [[ -d "${firmware_git_path}" && ! -L "${firmware_git_path}" ]] ; then
    cp -a $firmware_git_path /builds/OnlyKey-Firmware
else
    git clone $firmware_git_path /builds/OnlyKey-Firmware
    cd /builds/OnlyKey-Firmware
    git checkout $firmware_branch
    cd /builds
fi

##get firmware-commit 
cd /builds/OnlyKey-Firmware
commit=$(git rev-parse --verify HEAD | cut -c1-7)
cd /builds

#copy firmware
cp /builds/OnlyKey-Firmware/*.c ./arduino-1.6.5-r5/hardware/teensy/avr/cores/teensy3/.
cp /builds/OnlyKey-Firmware/*.h ./arduino-1.6.5-r5/hardware/teensy/avr/cores/teensy3/.

#copy custom libraries
if [[ -d "${libraries_git_path}" && ! -L "${libraries_git_path}" ]] ; then
    cp -a $libraries_git_path/* /builds/arduino-1.6.5-r5/libraries/.
else
    cd /builds/arduino-1.6.5-r5/libraries
    git init
    git remote add origin $libraries_git_path
    git pull origin $libraries_branch
    cd /builds
fi

cd /builds/arduino-1.6.5-r5
mv ./libraries/onlykey/onlykey.h ./libraries/onlykey/onlykey.h_orig
sed "s/.0\-test/.0\-${commit}/g" ./libraries/onlykey/onlykey.h_orig > ./libraries/onlykey/onlykey.h
/usr/bin/xvfb-run -- ./arduino --verify ../OnlyKey-Firmware/$firmware_file \
  --preferences-file ./preferences.txt \
  -v

cd /builds
rm -rf /builds/*.hex
cp /builds/build/*.hex /builds/.
rm -rf /builds/arduino-1.6.5-r5
#rm -rf /builds/OnlyKey-Firmware
rm -rf /builds/build


