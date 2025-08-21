# Wine-Byond-help
A collection of tips and tricks for getting byond running on linux<br />

This guide is mostly based on the [Lutris](https://lutris.net/games/byond/) installer for now however more general and other installers are planned (feel free to pr) 

# Please do not use the default Proton-Ge wine provided with lutris
## (note: the current lutris script should do this for you)
if not please log an issue and attempt the manuel download as described<br />
webview2 requires patches made to wine in 10.5. Proton is based on 10.0, so until the wine patches are ported to GE or proton gets rebased to 11.0 please use a system wine instead
<br /> <br />
<img width="1047" height="651" alt="image" src="https://github.com/user-attachments/assets/61b333a0-f9cf-48f9-b538-d41d1d5b92af" /><br />
<br /> <br />
to do so in lutris before running the install script please press the wine button on the left side tab and then select system wine as default <br />
make sure the wine is newer then 10.5 if it is not please google your distro's guide for installing wine to update it (we suggest using staging-wine while you are at it)<br />

<img width="850" height="514" alt="image" src="https://github.com/user-attachments/assets/87f50a35-9f87-4842-be2d-cdf022b5d3b3" /><br />
**alternatively if your package manager does not eaisly provide a sufficent wine version**<br />
you can press the small box icon and have lutris install some specfic wine versions. wine-10.8-staging-x86_64, wine-10.8-staging-tkg-ntsync-x86_64, and wine-10.7-staging-tk all work; however wine-10.8-staging-tkg-ntsync-x86_64 is recommended as its provides the best performance enhancing patches and supports NTSync which may (needs testing) improve byond performance in some facets.
TODO: test NTsync and add a guide for setting it up.


TODO: add guides for bottles and other installers<br />
<br />
arch: https://wiki.archlinux.org/title/Wine<br />
others: https://gitlab.winehq.org/wine/wine/-/wikis/Download<br />
TODO: add more links for distros <br />

# Installing a 32-bit prefix with lutris
32-bit prefix support for wine is slowly being deprecated and breaks alot of things. However wow64 doubles webview2's already high RAM usage so this is a temporary workaround until Wine fixes whatever bug causes webview to eat all of the ram<br />
<br />
First install a Wine binary with 32-bit prefix support I used this one [Arch Linux WINE-TKG NTSYNC WIN32 CI](https://github.com/JND94/wine-tkg-git/actions/workflows/wine-arch-ntsync-win32.yml)  and it seems alright<br />
(no fsync or esync support but they break byond sometimes anyway)<br />
<img width="1661" height="628" alt="image" src="https://github.com/user-attachments/assets/c0e84f00-fa0f-4ede-957f-a3e48ec7cb5e" /><br />
Click the newest one <br />
<img width="1882" height="660" alt="image" src="https://github.com/user-attachments/assets/7ded67f4-61cb-4761-ae99-4827eac8f6c3" /><br />
download the "artifact" you will need to then unzip it twice first a .zip and then a .tar.zst most distros can do this by default.<br />
<img width="1056" height="659" alt="image" src="https://github.com/user-attachments/assets/bb38f10a-dd32-4551-bfce-2f193e092511" /><br />
click on the gear next to Wine then in runner iptions set Wine Version to Custom. Finally select the wine binary from the package you just downloaded<br />
in my case it was at `~/Downloads/wine-tkg-staging-ntsync-git-10.13.r0.ga8a6d7b0-327-x86_64.pkg/usr/bin/wine`<br /> 
You will now be able to Use the 32-bit version of the lutris installer. <br />



# Common issues
## I dont have audio on arch
install `pipewire-alsa` or some equivalent make sure your audio driver is set to alsa and that should make it work

## Lutris/Wine is not closing/opening after one launch
webview2 brings with it the Microsoft Edge Updater which (randomly) starts itself and has a very peculiar senese of when it wants to close which blocks lutris/wine from closing and therefore opening again<br />
<br />
You have two simple solutions which both boil down to killing the Edge Updater <br />
<img width="1170" height="450" alt="image" src="https://github.com/user-attachments/assets/c2557a67-72f8-4832-8910-03366ce6b7fa" /><br />
1. open the wine task manager (you can do this in lutris by pressing on the wine glass and pressing wine taskmanager) then go to processes and then end `MicrosoftEdgeUpdate.exe*32` <br />
2. using your normal system task manager kill lutris/wine (depening on how you launch it) and then relaunch <br />


<br /><br />
after doing either of these you will be able to launch byond again without issue
<br /><br />
TODO: there is a script and some other ways to deal with this look into it and add them as the "hard way"

## mangohud does not work!
byond is 32 bit you need the 32 bit mango hud to have it work<br />
if you have it installed make sure dxvk is enabled some older installers disable it for byond

## Bad FPS on Nividia cards
enabling dxvk has helped alot with fixing fps issues on team green cards but others have reported it breaking Byond completely so try it and see which one are you!<br />
this has also been noted to sometimes cause flickering in tguis

## Nothing is rendering!!
not sure the cause of this but the easiest try disabling esync and fsync; exiting full-screen also seems to help sometimes. <br />
If those did not fix it or if you want a more stable solution [ntsync](https://docs.kernel.org/next/userspace-api/ntsync.html) has been found to a fix it as well. <br />
If your kernel is newer then 6.15 it is as simple as `# modprobe ntsync` and having a ntsync patched wine (the lutris script has this by default.) this will only enable it until you restart your computer but all distros have solutions for permanent module loading <br />
<br />
Here is some instructions for working with modules:<br />
[Arch](https://wiki.archlinux.org/title/Kernel_module)<br />
[Fedora](https://docs.fedoraproject.org/en-US/fedora/f40/system-administrators-guide/kernel-module-driver-configuration/Working_with_Kernel_Modules/)<br />
[Mint](https://forums.linuxmint.com/viewtopic.php?t=449946)<br />
(Note: if you use a kenel newer then 6.15 you only need to use modprobe and the ntsync.conf; The udev rules are not needed)<br />
TODO: add more for more distros

## Byond is using a ton of memory!
Webview 2 under Wine suffers from some sort of bug that causes it to max out on ram usage no matter what. This is exacerbated by wow64 where the previous 32-bit webview would take 4.5 gb the new 64-bit now takes around 9.5 (tested on tgmc)
Ill post a bug report on wine but for now we only have work arounds. <br />
There is two "solutions." <br />
1. (Recommended) Just add more swap. A swap file uses your hard-drive as ram as webview is being buggy this wont even slow you down as most of the bloated ram wont even be used. If you have 16 Gibs, 20 Gibs of swap is suggested and plenty (increase the swap as needed or as you want more browser tabs open while you are playing)
- Here are some guides for setting up/increasing swap.<br />
[Arch](https://wiki.archlinux.org/title/Swap)<br />
[Fedora](https://discuss.techlore.tech/t/how-to-increase-swap-size-in-fedora-linux/5802/2)<br />
[Mint](https://forums.linuxmint.com/viewtopic.php?t=284301)<br />
<br />

2. if you dont care about spaceman dm breaking or using deprecated features using a 32-bit prefix will cut that 9.5 gib ram footprint in half! This may still not be enough but it is a nice savings.<br />
scroll up to 'Installing a 32-bit prefix with lutris' and follow that.<br />

TODO: add manuel install instructions for 32-bit<br />
TODO: make winehq bug report<br />

## If you dont see your issue here please open a issue on this repo 
I and others really dont mind helping people getting this setup

# TODO: guide for setting up default prefix and vscode dev enviroment
