# Carla-on-Ubuntu
Building .deb packages of Carla audio plugin host for Ubuntu.
  
### Note:
* Tested to work on Ubuntu 16.10 (Yakkety) and 17.04 (Zesty) with the Ubunto Studio repo's installed.
* The build script will install self built linuxsampler packges to be able to build and install Carla on Ubuntu.
* You will need tpo update builder info and emails in control, changelog, and so on before building.
  
### To build
chmod 755 ./build_carla.sh  
sudo ./build_carla.sh  

