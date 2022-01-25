# Arch Install Scripts

This is a quick and dirty script for installing Arch linux

It was just written because I had to install Arch multiple times and wanted a way to automate it. Feel free to use it, but be aware that there is no error trapping and its far from optimised. Also you'll need to manually make changes to it since it's written according to my personal needs. Finally, it's had minimal testing so there is a very good chance that you'll have problems when running it.

## Usage

If your needs are almost identical to mine, just update the variables at the top of each script with your information.

The dependencies are minimal but be aware when disabling parts of the script or adding new packages.

## Future

When I next have an unused machine that I can repeatedly run the install on without data retention issues, I'll try to make the following changes:

 1. Structure the script in a more sensible way
 1. Add trap common errors
 1. Allow the variables at the top of the script to be specified at runtime
 1. Add some kind of menu for selecting packages to install
 1. Add some kind of menu for selecting a drive for installation from a list
 1. Add options for more alternative packages such as a different desktop environment, Xorg vs Wayland, etc.