# GPX-QMapShack-to-OruxMaps
Graphical user interface to convert GPX files exported from *QMapShack* for import into *OruxMaps*


### About
Conversion tool maps QMapShack tracks and waypoints to OruxMaps tracks and waypoints. *BRouter* OSM offline router is used to optionally
- add direction waypoints based on selected BRouter profile and track variant
- add direction waypoint labels
- add track's support points


Converted GPX files are ready to re-import into QMapShack too. In order to see direction waypoint symbols on map, user-defined QMapShack waypoint symbols equally named to OruxMaps waypoint symbols must exist.

### Graphical user interface
Graphical user interface is a single script written in _Tcl/Tk_ scripting language and is executable on _Microsoft Windows_ and _Linux_ operating system. Language-neutral script file _GPX-QMapShack-to-OruxMaps.tcl_ requires an additional user settings file and at least one localized resource file. Additional files must follow _Tcl/Tk_ syntax rules too. 

User settings file is named _GPX-QMapShack-to-OruxMaps.ini_. A template file is provided.

Resource files are named _GPX-QMapShack-to-OruxMaps.<locale\>_, where _<locale\>_ matches locale’s 2 lowercase letters ISO 639-1 code. English localized resource file _GPX-QMapShack-to-OruxMaps.en_ and German localized resource file _GPX-QMapShack-to-OruxMaps.de_ are provided. Script can be easily localized to any other system’s locale by providing a corresponding resource file using English resource file as a template. 

Screenshot of graphical user interface: 

![Image](https://github.com/user-attachments/assets/9b5472c9-baf8-4123-b749-e9a160b5b719)

![Image](https://github.com/user-attachments/assets/fc166fb9-9630-443c-aebf-31c60a700ad0)


### Installation

1.	**BRouter configurable OSM offline router**  
Download and install latest BRouter version from [download section](https://github.com/abrensch/brouter/releases).  
Download the required segment data files of the regions of your interest into BRouter's *segments* folder. See [README](https://github.com/abrensch/brouter?tab=readme-ov-file) where to download segments data files.  

2.	**Java runtime environment (JRE) or Java development kit (JDK)**  
JRE version 17 or higher is required.  
Each JDK contains JRE as subset.  
**Windows**: If not yet installed, download and install JRE or JDK, e.g. from [Oracle](https://www.java.com), [OpenLogic](https://www.openlogic.com/openjdk-downloads) or [Adoptium](https://adoptium.net/de/temurin/releases).  
**Linux**: If not yet installed, install JRE or JDK using Linux package manager.  
(Ubuntu: _apt install openjdk-<version\>-jre_ or _apt install openjdk-<version\>-jdk_ with required or newer _<version\>_)  
**macOS**: If not yet installed, install JDK using _Homebrew_ package manager by _brew install java_.  

3.	**Tcl/Tk scripting language version 8.6 or higher binaries**  
**Windows**: Download and install latest stable version of Tcl/Tk, currently 9.0.  
See https://wiki.tcl-lang.org/page/Binary+Distributions for available binary distributions. Recommended Windows binary distribution is from [teclab’s tcltk](https://gitlab.com/teclabat/tcltk/-/packages) Windows repository. Select most recent installation file _tcltk90-9.0.\<x.y>.Win10.nightly.\<date>.tgz_. Unpack zipped tar archive (file extension _.tgz_) into your Tcl/Tk installation folder, e.g. _%ProgramFiles%/Tcl_.  
Note: [7-Zip](https://www.7-zip.org) file archiver/extractor is able to unpack _.tgz_ archives.   
**Linux**: Install packages _tcl, tcllib, tcl-thread, tk_ and _tklib_ using Linux package manager. 
(Ubuntu: _apt install tcl tcllib tcl-thread tk tklib_)   
**macOS**: If not yet installed, install _tcl-tk_ using _Homebrew_ package manager by _brew install tcl-tk_. Advanced users can either download additionally required Tcl/Tk package _tklib0.9_ from [sourceforge.net](https://sourceforge.net/projects/tcllib/files/tklib/0.9) and install into folder _/usr/local/Cellar/tcl-tk/*/lib/tklib0.9_ or simply copy _tklib0.9_ folder from an existing Windows or Linux installation of Tcl/Tk.  

4.	**GPX-QMapShack-to-OruxMaps graphical user interface script**  
Download language-neutral script file _GPX-QMapShack-to-OruxMaps.tcl_, user settings file _GPX-QMapShack-to-OruxMaps.ini_ and at least one localized resource file.  
**Windows**: Copy downloaded files into installation folder, e.g. into folder _%programfiles%/GPX Tools_.  
**Linux** and **macOS**: Copy downloaded files into installation folder, e.g. into folder _~/GPX Tools_.  
**Note**: Edit _user-defined script variables settings section_ of user settings file _GPX-QMapShack-to-OruxMaps.ini_ to match files and folders of your local installation of BRouter and Java. Always use character slash “/” as directory separator in script, for Microsoft Windows too!

### Script file execution

**Windows**:  
Associate file extension _.tcl_ to Tcl/Tk window shell’s binary _wish.exe_. Right-click script file and open file’s properties window. Change data type _.tcl_ to be opened by _Wish application_ e.g. by executable _%programfiles%/Tcl/bin/wish.exe_. Once file extension has been associated, double-click script file to run.  

**Linux**:  
Either run script file from command line by
```
wish <path-to-script>/GPX-QMapShack-to-OruxMaps.tcl
```
or create a desktop starter file _GPX-QMapShack-to-OruxMaps.desktop_
```
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Name=GPX-QMapShack-to-OruxMaps
Exec=wish <path-to-script>/GPX-QMapShack-to-OruxMaps.tcl
```
or associate file extension _.tcl_ to Tcl/Tk window shell’s binary _/usr/bin/wish_ and run script file by double-click file in file manager.  

**macOS**:  
Either run script file from command line by
```
wish <path-to-script>/GPX-QMapShack-to-OruxMaps.tcl
```

or use _Automator -> Application -> Run Shell Script -> /usr/local/bin/wish \"$@\"_ to create an application for Tcl/Tk window shell’s binary _wish_, then associate all _.tcl_ files to this application and run script file by double-click file in file manager.

Having _.tcl_ files associated to this application, a desktop starter from script file can be created by _Make Alias_ and dragging the alias and dropping it to desktop.  

### Example

Part of track from *Notre Dame de la Gorge* to *Les Chapieux* of trekking *Tour du Mont Blanc*

Screenshot 1 - QMapShack:  
Track with waypoints as originally created with QMapShack and exported as GPX file  
![Image](https://github.com/user-attachments/assets/1fab7469-42a3-4aab-b1a1-8ff15ad56e19)

Screenshot 2 - QMapShack:  
Direction waypoints with waypoint labels added by GUI from exported GPX file and re-imported newly generated GPX file into QMapShack  
![Image](https://github.com/user-attachments/assets/eac8418d-2ebf-4422-8eb4-49f563381c57)

Screenshot 3 - OruxMaps:  
Imported newly generated GPX file into OruxMaps  
![Image](https://github.com/user-attachments/assets/743a262f-a508-497a-9876-0c3d5ccdc8ab)

