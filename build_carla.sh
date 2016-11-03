#!/usr/bin/env bash

function verify_packages
{
    # Make sure to have one of the following installed :
    # 	libgl1-mesa-dev
    # or
    # 	libgl-dev libglu1-mesa-dev
    # or
    # 	libglu-dev

    error1=0
    error2=0
    error3=0
    error4=0

    if [ $(dpkg-query -W -f='${Status}' libgl1-mesa-dev 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
        error1=1
    fi

    if [ $(dpkg-query -W -f='${Status}' libgl-dev 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
        error2=1
    fi

    if [ $(dpkg-query -W -f='${Status}' libglu1-mesa-dev 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
        error3=1
    fi

    if [ $(dpkg-query -W -f='${Status}' libglu-dev 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
        error4=1
    fi

    if [ $error1 -eq 1 ] && [ $error2 -eq 1 ] && [ $error3 -eq 1 ] && [ $error4 -eq 1 ]; then
        echo -e "\nMissing  GL libraries, install one of the following packages.\n"
        echo    "    libgl1-mesa-dev"
        echo    "    or"
        echo    "    libgl-dev libglu1-mesa-dev"
        echo    "    or"
        echo -e "    libglu-dev\n\n"
        echo -e "Note: Which one will depend on your system setup\n"
        exit 1
    fi

    # Check for all dependencies

DEPENDENCIES="pyqt5-dev-tools pyqt5-dev qtbase5-dev qtbase5-dev-tools libgtk2.0-dev libgtk-3-dev
    libasound2-dev libmagic-dev libpulse-dev libjack-jackd2-dev libx11-dev libxft-dev
    liblo-dev libfltk1.3-compat-headers libfltk1.3-dev libzita-alsa-pcmi-dev
    libzita-convolver-dev libzita-resampler-dev libmxml-dev libfftw3-dev
    libsmf-dev libsndfile1-dev python3-rdflib python3-pyqt5.qtsvg python3-liblo
    libffi-dev libglib2.0-dev libclthreads-dev libclxclient-dev
    libfreetype6-dev libpng-dev libxft-dev zlib1g-dev libcairo2-dev
    libfluidsynth-dev libprojectm-dev libgig-dev liblscp-dev libsqlite3-dev"
    stringarray=($DEPENDENCIES)

    for depends in "${stringarray[@]}"
    do
        if [ $(dpkg-query -W -f='${Status}' $depends 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
            echo -e "\nMissing package dependency: $depends\n"
            echo -e "try 'sudo apt install $depends'\n"
            exit 1
        fi
    done
}

# build linuxsampler packages

function build_linuxsampler
{
    echo -e "\ninstalling liblinuxsampler\n"
    if [ ! -e linuxsampler-2.0.0.tar.bz2 ]; then
        wget http://download.linuxsampler.org/packages/linuxsampler-2.0.0.tar.bz2
    fi
    if [ ! -e linuxsampler-2.0.0.tar.bz2 ]; then
        echo -e "\nERROR missing linuxsampler-2.0.0.tar.bz2\n"
        exit 1
    fi
    if [ ! -e linuxsampler-2.0.0 ]; then
        tar -xf linuxsampler-2.0.0.tar.bz2
    fi
    cd linuxsampler-2.0.0
    dpkg-buildpackage -uc -us -b
    cd ..
}

function install_linuxsampler
{
    sudo dpkg -i liblinuxsampler_2.0.0-1_amd64.deb \
        liblinuxsampler-dev_2.0.0-1_amd64.deb \
        linuxsampler_2.0.0-1_amd64.deb
}

function build_carla
{
    if [ -e carla-git ]; then
        rm -fr carla-git
    fi
    git clone https://github.com/falkTX/Carla.git carla-git
    cd carla-git
    patch -p1 < ../../patches/carla-makefile.diff
    cp -pr  ../../debian .

    CURRENTBUILDDATE=$(date --utc '+%a, %d %b %Y %H:%M:%S %z')
    CURRENTDATE=$(date +%Y%m%d)
    CURRENTGITHASH=$(git rev-parse --short=8 HEAD)

    echo "Setting date to $CURRENTDATE"
    sed -i "s/insertdate/$CURRENTDATE/g" debian/changelog

    echo "Using git hash $CURRENTGITHASH"
    sed -i "s/githash/$CURRENTGITHASH/g" debian/changelog

    echo "Build time and date set to '$CURRENTBUILDDATE'"
    sed -i "s/buildtimeanddate/$CURRENTBUILDDATE/g" debian/changelog

    dpkg-buildpackage -uc -us -b
    cd ..
}

function install_carla
{
    sudo dpkg -i carla*.deb
}

function backup_debs
{
    if [ ! -e ../debs ]; then
        mkdir ../debs
    fi
    rm ../debs/*.deb > /dev/null
    mv *.deb ../debs
}

function clean_up
{
    rm -fr build-carla
}

###########################################################
#
#    Carla audio plugin installation script for Ubuntu
#
###########################################################

if [ ! -e build-carla ]; then
    mkdir build-carla
fi
cd build-carla

echo -e "\nVerifying package dependencies\n"
verify_packages

if [ $(dpkg-query -W -f='${Status}' liblinuxsampler-dev 2>/dev/null | grep -c "ok installed") -ne 0 ]; then
    echo -e "\nliblinuxsampler-dev already installed, not building it.\n"
else 
    echo -e "\nvuilding liblinuxsampler\n"
    build_linuxsampler
    echo -e "\ninstalling liblinuxsampler\n"
    install_linuxsampler
fi

echo -e "\nbuilding carla\n"
build_carla
echo -e "\ninstalling carla\n"
install_carla

echo -e "\nbackup packages\n"
backup_debs

cd ..

echo -e "\nclean up\n"
clean_up
