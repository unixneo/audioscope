#!/bin/bash
#
# AudioScope.sh
#
# Public Domain, 2013-2020, B.Walker, G0LCU.
# Issued under the Creative Commons, CC0, licence.
#
# If you have any comments good or bad with what you see please send an email to:-
# wisecracker.bazza@gmail.com
# Thank you in advance...
#
# IMPORTANT!!! This code assumes that it is saved as AudioScope.sh inside your _home_ drawer...
# Set the permissions to YOUR requirements and launch the code using the following:-
#
# Your Prompt> ./AudioScope.sh<CR>
#
# VERY IMPORTANT!!! Some Linux/*NIX installs might require that you run this code in root mode
# inside a terminal for ALL the possible available facilities. Arduino access is one possible event.
# Be very, VERY aware of this!!! If you do run a terminal in root mode, you do so at your own risk.
# Also there might be some dependencies beyond my control too, e.g. 'xterm' is not part of a default
# install on Linux Mint 17, so therefore be aware of any of these anomalies too. It is now hidden in
# OSX 10.11.x and above but is now recoded for OSX 10.12.x's terminal.
# Linux users will still have to fend for themselves. ;o)
#
# This is being developed primarily on a MacBook Pro 13 inch, OSX 10.12.x minimum; bash version...
# GNU bash, version 3.2.57(1)-release (x86_64-apple-darwin16), Copyright (C) 2007 Free Software Foundation, Inc.
# Also tested on PCLinuxOS 2009 and Debian 6.0.x, 32 bit, for backwards compatibility.
# CygWin and CygWin64 are also catered for but some operations WILL be very, very slow.
# Now testing includes Linux Mint 19, 64 bit as a Linux OS.
# All references to Debian 6.0.x cease as of AudioScope.sh Version 0.30.40.
# All references to PCLinuxOS 2009 also cease as of version 0.31.20.
# An iMAC, OSX 10.12.x, Sierra. OSX 10.7.x to 10.11.x are no longer catered for.
# The experimental Quicktime Player capture now does NOT work BELOW El Capitan, but SOX does. It does
# NOW work on OSX 10.12.x, Sierra. It takes a few seconds for a single capture, but HEY, it works on
# a virgin OSX 10.12.x, Sierra install and requires absolutely no dependences.
# OSX 10.13.x and above now ask for confirmation to allow the terminal to use the microphone, etc.
#
# Windows "SoundRecorder.exe" no longer exists in Windows 10, (it is now called "Voice Recorder"),
# so this capture mode is now broken as of 29th July, 2016. Therefore "/dev/dsp" is the only capture
# mode for CygWin and CygWin64. SOX is not catered for in CygWin. If you want to capture via any
# other method in CygWin(64) you will have to experiment for yourselves.
#
# Official releases at these two sites/forums below:-
# https://www.unix.com/shell-programming-and-scripting/212939-start-simple-audio-scope-shell-script.html
# Which now follows on here:-
# https://www.unix.com/os-x-apple-/269769-audioscope-project.html
# These sites may have unofficial releases too.
#
# Due to issues I had with github this URL is no longer being updated for the time being!
# httpss://github.com/wisecracker-bazza/Scope
# Many photos can be found here however...
#
# At this point I will include and say thank you to "Corona688", a member of...
# https://www.unix.com for his input. His input has been invaluable.
# Also to "Don Cragun" and others on the same site for their input too.
# Also to "MadeInGermany" on the same site who helped with a problem found with the 'find' command when detecting 'SOX'.
# Also to "xbin" who showed me the way to create a second terminal in OSX 10.12.x instead of my method.
# Many thanks also go to the guys who have helped with this on...
# https://www.linuxformat.com for all your input too. The Forums section of this site now no longer exists.
# Also to an anonymous person, nicknamed Zoonie, who has given this project some serious hammering in the past...
# Finally, thanks to my wife for putting up with my coding experiments... ;o)

# #########################################################
# Startup, terminal size detect, setup and progress screen.
set -u
# Save the default terminal size as an array.
term_size=($( stty size ))
# Attempt to set the terminal size to 24 x 80 to allow for non standard terminal sizes.
# This may NOT work in every terminal so you will have to manually resize the terminal window.
printf "%b" "\x1B[8;24;80t"
if [ "$( stty size )" != "24 80" ]
then
	echo ""
	echo "A terminal window size of 24 lines x 80 columns IS required"
	echo "for this program to work..."
	echo ""
	echo "This terminal will not auto-resize using the escape codes."
	echo ""
	echo "You will have to manually resize the terminal to EXACTLY"
	echo "24 lines x 80 columns and restart AudioScope.sh again..."
	echo ""
	echo "Aborting program..."
	echo ""
	exit 1
fi
# If all OK continue...
printf "%b" "\x1B[2J\x1B[H\x1B[2;34fIMPORTANT!!!"
printf "%b" "\x1B[3;34f------------"
printf "%b" "\x1B[5;13fTERMINAL ESCAPE CODES  ARE USED EXTENSIVELY THROUGHOUT"
printf "%b" "\x1B[6;13fTHE PROGRAM RUN.  PICK A TERMINAL FOR THIS CAPABILITY."
printf "%b" "\x1B[9;13fPlease wait while everything required is being set up."
printf "%b" "\x1B[10;13fFor CygWin users this might take quite a long time...."
printf "%b" "\x1B[12;13fProgress ."
# Create a working 'Temp' directory to save files permanently. Every program 'RESET<CR>' will refresh the files.
if [ ! -d "$HOME"/AudioScope.tmp ]
then
	mkdir "$HOME"/AudioScope.tmp
	chmod 755 "$HOME"/AudioScope.tmp
fi
printf "."

# #########################################################
# Variables in use.
ifs_str="$IFS"
ver="0.70.01"
version=" \$VER: AudioScope.sh_Version_""$ver""_2013-2020_Public_Domain_B.Walker_G0LCU."
setup="$version"
blankline="                                                                            "
# Default first time run capture mode, 0 = DEMO.
demo=0
capturemode="DEMO"
# Change this absolute address for your location of "sox" _IF_ you know where it is...
capturepath="/dev/urandom"
device=$capturepath
# Draw procedure mode, 0 = OFF.
drawline=0
# Pseudo-continuous data file saving.
savefile="0000000000"
save_string="OFF"
hold=1
status=1
laststatus=0
foreground=37
# "count", "number", "char" and "str" are reusable, throw away variables.
count=0
number=0
char='$VER: AudioScope.sh_(C)2013-2020_B.Walker_G0LCU_Released_Under_CC0_Licence.'
str='$VER: AF_Spec_An.sh_(C)2017-2020_B.Walker_G0LCU_Released_Under_CC0_Licence.'
# Vertical components.
# vert_one and vert_two are the vertical plotting points for the draw() function.
vert_one=2
vert_two=2
vert=12
vert_shift=2
vshift="?"
vert_array=""
vert_draw=9
vertical="Uncalibrated (m)V/DIV"
# Display setup...
polarity=1
# Keyboard components.
kbinput="?"
tbinput=1
# "str_len" is a reusable variable IF required.
str_len=1
# "grab" is used for internal pseudo-synchronisation.
grab=0
# "sound_card_zero_offset" can only be manually changed in the AudioScope.Config file, OR, here.
sound_card_zero_offset=-2
# Zoom facility default status line.
zoom_facility="OFF"
zoom="Lowest sensitivity zoom/gain, default condition..."
# Horizontal components.
horiz=9
# Scan retraces.
scan=1
scanloops=1
# Timebase variable components.
timebase="Uncalibrated (m)S/DIV"
subscript=0
# "scan_start" is from 0 to ( length of file - 64 ), initialised at 1024...
scan_start=1024
# "scan_jump" is from 1 to ( ( ( scan_end - scan_start ) / 64) + 1 )...
scan_jump=1
# "scan_end" is at least 64 bytes in from the absolute file end.
scan_end=47930
# Synchronisation variables.
# synchronise switches the synchronisation ON or OFF.
synchronise="OFF"
# sync_point is any value between 15 and 240 of the REAL grab(s).
sync_point=128
sync_input="?"
ext_trig_array=""
# Frequency counter AC and DC condition variables, 'coupling_device' relates to the author's machine.
coupling="AC"
dc_flag=0
altdc="V"
coupling_device="/dev/urandom"
first_listing="?"
second_listing="?"
# Generate some raw files and a wave file too.
wave_form=0
dc_data=0
dc_str="0.000"
data="Creative Commons, CC0 Licence, (Public Domain), 2013-2020, B.Walker, G0LCU."
# "freq" will always be reset to "2000" on program exit.
freq="  OFF  "
freq_array=""
# Determine if running in CygWin or other modes...
u_name=$( uname )
printf "."
if [ ! -f "$HOME"/AudioScope.tmp/waveform.raw ]
then
	# Generate a 65536 byte raw 1KHz sinewave file from hex "data".
	data="\\x80\\x26\\x00\\x26\\x7F\\xD9\\xFF\\xD9"
	: > "$HOME"/AudioScope.tmp/sinewave.raw
	chmod 644 "$HOME"/AudioScope.tmp/sinewave.raw
	for wave_form in {0..12}
	do
        	data=$data$data
	done
	printf "%b" "$data" >> "$HOME"/AudioScope.tmp/sinewave.raw
	printf "."
	# Using the new sinewave.raw, _copy_ and convert to a ?.WAV file for multi-platform test usage.
	# Transferred this to my mobile 'phone and I now have a portable signal source.
	: > "$HOME"/AudioScope.tmp/sinewave.wav
	chmod 644 "$HOME"/AudioScope.tmp/sinewave.wav
	printf "%b" "\x52\x49\x46\x46\x24\x00\x01\x00\x57\x41\x56\x45\x66\x6d\x74\x20\x10\x00\x00\x00\x01\x00\x01\x00\x40\x1f\x00\x00\x40\x1f\x00\x00\x01\x00\x08\x00\x64\x61\x74\x61\x00\x00\x01\x00" >> "$HOME"/AudioScope.tmp/sinewave.wav
	cat "$HOME"/AudioScope.tmp/sinewave.raw >> "$HOME"/AudioScope.tmp/sinewave.wav
	printf "."
	# Generate two 65536 byte 1KHz pulse files in .WAV format only.
	data="\\xFF\\x00\\x00\\x00\\x00\\x00\\x00\\x00"
	: > "$HOME"/AudioScope.tmp/pulse1.wav
	chmod 644 "$HOME"/AudioScope.tmp/pulse1.wav
	printf "%b" "\x52\x49\x46\x46\x24\x00\x01\x00\x57\x41\x56\x45\x66\x6d\x74\x20\x10\x00\x00\x00\x01\x00\x01\x00\x40\x1f\x00\x00\x40\x1f\x00\x00\x01\x00\x08\x00\x64\x61\x74\x61\x00\x00\x01\x00" >> "$HOME"/AudioScope.tmp/pulse1.wav
	for wave_form in {0..12}
	do
		data=$data$data
	done
	printf "%b" "$data" >> "$HOME"/AudioScope.tmp/pulse1.wav
	printf "."
	data="\\x00\\xFF\\xFF\\xFF\\xFF\\xFF\\xFF\\xFF"
	: > "$HOME"/AudioScope.tmp/pulse2.wav
	chmod 644 "$HOME"/AudioScope.tmp/pulse2.wav
	printf "%b" "\x52\x49\x46\x46\x24\x00\x01\x00\x57\x41\x56\x45\x66\x6d\x74\x20\x10\x00\x00\x00\x01\x00\x01\x00\x40\x1f\x00\x00\x40\x1f\x00\x00\x01\x00\x08\x00\x64\x61\x74\x61\x00\x00\x01\x00" >> "$HOME"/AudioScope.tmp/pulse2.wav
	for wave_form in {0..12}
	do
		data=$data$data
	done
	printf "%b" "$data" >> "$HOME"/AudioScope.tmp/pulse2.wav
	printf "."
	# Now generate a 48000 byte 6KHz sinewave for test loading.
	data="\\x80\\x26\\x00\\x26\\x7F\\xD9\\xFF\\xD9"
	: > "$HOME"/AudioScope.tmp/0000000000.BIN
	chmod 644 "$HOME"/AudioScope.tmp/0000000000.BIN
	for wave_form in {0..5999}
	do
		printf "%b" "$data" >> "$HOME"/AudioScope.tmp/0000000000.BIN
	done
	printf "."
	# Generate a raw sample for the Windows SoundRecorder.exe access for CygWin.
	: > "$HOME"/AudioScope.tmp/sample.raw
	cp "$HOME"/AudioScope.tmp/0000000000.BIN "$HOME"/AudioScope.tmp/sample.raw
	chmod 644 "$HOME"/AudioScope.tmp/sample.raw
	printf "."
	# Generate an 8000 byte raw 2000Hz squarewave file for DEMO mode from "data".
	data="\\x00\\x00\\xFF\\xFF\\x00\\x00\\xFF\\xFF"
	: > "$HOME"/AudioScope.tmp/squarewave.raw
	chmod 644 "$HOME"/AudioScope.tmp/squarewave.raw
	for wave_form in {0..999}
	do
		printf "%b" "$data" >> "$HOME"/AudioScope.tmp/squarewave.raw
	done
	printf "."
	# Generate a first copy of "waveform.raw" for this script.
	cp "$HOME"/AudioScope.tmp/squarewave.raw "$HOME"/AudioScope.tmp/waveform.raw
	chmod 644 "$HOME"/AudioScope.tmp/waveform.raw
	printf "."
	cp "$HOME"/AudioScope.tmp/squarewave.raw "$HOME"/AudioScope.tmp/symmetricalwave.raw
	printf "."
	# Create a "symmetricalwave.wav" file.
	echo "" > "$HOME"/AudioScope.tmp/symmetricalwave.wav
	chmod 644 "$HOME"/AudioScope.tmp/symmetricalwave.wav
	printf "."
	# This is likely to change but create a single byte size "dcdata.raw" file for Arduino.
	echo "" > "$HOME"/AudioScope.tmp/dcdata.raw
	chmod 644 "$HOME"/AudioScope.tmp/dcdata.raw
	printf "."
	# Generate a signed16bit.txt file for Windows CygWin.
	echo "" > "$HOME"/AudioScope.tmp/signed16bit.txt
	chmod 644 "$HOME"/AudioScope.tmp/signed16bit.txt
	printf "."
	# Generate a waveform.wav file for Windows CygWin.
	: > "$HOME"/AudioScope.tmp/waveform.wav
	chmod 644 "$HOME"/AudioScope.tmp/waveform.wav
	cp "$HOME"/AudioScope.tmp/sinewave.wav "$HOME"/AudioScope.tmp/waveform.wav
	printf "."
	# Generate a sweeper.raw file.
	: > "$HOME"/AudioScope.tmp/sweeper.raw
	for number in {1..10}
	do
		cat "$HOME"/AudioScope.tmp/squarewave.raw >> "$HOME"/AudioScope.tmp/sweeper.raw
	done
	chmod 644 "$HOME"/AudioScope.tmp/sweeper.raw
	printf "."
	# Generate a sweep.raw file.
	echo "" > "$HOME"/AudioScope.tmp/sweep.raw
	chmod 644 "$HOME"/AudioScope.tmp/sweep.raw
	printf "."
	# Generate a sweep.wav file.
	echo "" > "$HOME"/AudioScope.tmp/sweep.wav
	chmod 644 "$HOME"/AudioScope.tmp/sweep.wav
	printf "."
	# Generate the pulsetest.sh file.
	echo "" > "$HOME"/AudioScope.tmp/pulsetest.sh
	chmod 755 "$HOME"/AudioScope.tmp/pulsetest.sh
	printf "."
	# Generate the Arduino_9600.pde file.
	echo "" > "$HOME"/AudioScope.tmp/Arduino_9600.pde
	chmod 666 "$HOME"/AudioScope.tmp/Arduino_9600.pde
	printf "."
	# Generate the Untitled.m4a file.
	echo "" > "$HOME"/AudioScope.tmp/Untitled.m4a
	chmod 666 "$HOME"/AudioScope.tmp/Untitled.m4a
	printf "."
	# Generate the AudioScope.Manual file.
	echo "" > "$HOME"/AudioScope.Manual
	chmod 644 "$HOME"/AudioScope.Manual
	printf "."
	# Generate the AudioScope_Quick_Start.Notes file.
	echo "" > "$HOME"/AudioScope_Quick_Start.Notes
	chmod 644 "$HOME"/AudioScope_Quick_Start.Notes
	printf "."

	# #########################################################
	# FOR ALL USERS!!!                                TESTED!!!
	# The lines below, from ": >" to "#xterm", will generate a new shell script and execute it in a new xterm terminal...
	# Just EDIT out the two comments below to automatically use it.
	# When this script is run it generates a 1KHz sinewave in a separate window that lasts for 8 seconds and then re-runs
	# after a 2 second delay. After calibration of the timebase ranges these two lines can be commented out again but the
	# file is generated still so that it can be run manually IF required.
	# To quit this script and close the window just press Ctrl-C in the 2 second silence and the program exits.
	# This generator will be needed for calibration checks of some timebase ranges.
	: > "$HOME"/AudioScope.tmp/1KHz-Test.sh
	chmod 744 "$HOME"/AudioScope.tmp/1KHz-Test.sh
	printf "%b" '#!/bin/bash\n' >> "$HOME"/AudioScope.tmp/1KHz-Test.sh
	printf "%b" 'printf "%b" "\\x1B]0;1KHz Sinewave Generator.\\x07"\n' >> "$HOME"/AudioScope.tmp/1KHz-Test.sh
	printf "%b" 'while true\n' >> "$HOME"/AudioScope.tmp/1KHz-Test.sh
	printf "%b" 'do\n' >> "$HOME"/AudioScope.tmp/1KHz-Test.sh
	printf "%b" '        clear\n' >> "$HOME"/AudioScope.tmp/1KHz-Test.sh
	printf "%b" '        echo ""\n' >> "$HOME"/AudioScope.tmp/1KHz-Test.sh
	printf "%b" '        echo "PRESS Ctrl-C INSIDE THE 2 SECOND SILENCE TO EXIT..."\n' >> "$HOME"/AudioScope.tmp/1KHz-Test.sh
	printf "%b" '        echo "IGNORE ANY ERRORS AS THIS IS DELIBERATELY ALLOWED..."\n' >> "$HOME"/AudioScope.tmp/1KHz-Test.sh
	printf "%b" '        echo ""\n' >> "$HOME"/AudioScope.tmp/1KHz-Test.sh
	printf "%b" '        echo "Apple OSX 10.7.x and greater, afplay command..."\n' >> "$HOME"/AudioScope.tmp/1KHz-Test.sh
	printf "%b" '        afplay "$HOME"/AudioScope.tmp/sinewave.wav\n' >> "$HOME"/AudioScope.tmp/1KHz-Test.sh
	printf "%b" '        echo ""\n' >> "$HOME"/AudioScope.tmp/1KHz-Test.sh
	printf "%b" '        echo "Linux ALSA, aplay command..."\n' >> "$HOME"/AudioScope.tmp/1KHz-Test.sh
	printf "%b" '        aplay "$HOME"/AudioScope.tmp/sinewave.wav\n' >> "$HOME"/AudioScope.tmp/1KHz-Test.sh
	printf "%b" '        echo ""\n' >> "$HOME"/AudioScope.tmp/1KHz-Test.sh
	printf "%b" '        echo "Finally, Linux and others, /dev/dsp version..."\n' >> "$HOME"/AudioScope.tmp/1KHz-Test.sh
	printf "%b" '        cat "$HOME"/AudioScope.tmp/sinewave.raw > /dev/dsp\n' >> "$HOME"/AudioScope.tmp/1KHz-Test.sh
	printf "%b" '        sleep 2\n' >> "$HOME"/AudioScope.tmp/1KHz-Test.sh
	printf "%b" 'done\n' >> "$HOME"/AudioScope.tmp/1KHz-Test.sh
	chmod 755 "$HOME"/AudioScope.tmp/1KHz-Test.sh
	#delay 1
	#xterm -e "$HOME"/AudioScope.tmp/1KHz-Test.sh &
	# For all users end.
	printf "."

	# #########################################################
	# This section is for future usage only at this point.
	# It contains the running scripts for vertical calibration
	# For *NIX and Linux flavours plus Windows XP, Vista and Windows 7.
	# #########################################################
	# FOR Windows SOund eXchange USERS ONLY!!!       TESTED !!!
	# NOTE:- The code itself DOES work but generating it on the fly has NOT been tested yet.
	# Windows batch file square wave generator using SOund eXchange, SOX.
	# Just TRANSFER the file "$HOME"/AudioScope.tmp/VERT_BAT.BAT to a Windows machine and run from Windows Command Prompt.
	# *** You WILL need to change the absolute path on the last line for YOUR SOX installation. ***
	# It is in uncommented mode so that anyone interested can experiment _immediately_.
	: > "$HOME"/AudioScope.tmp/VERT_BAT.BAT
	echo -e -n '@ECHO OFF\r\n' >> "$HOME"/AudioScope.tmp/VERT_BAT.BAT
	echo -e -n 'CLS\r\n' >> "$HOME"/AudioScope.tmp/VERT_BAT.BAT
	echo -e -n 'SET "rawfile=\xFE\xFE\xFE\xFE\x01\x01\x01\x01"\r\n' >> "$HOME"/AudioScope.tmp/VERT_BAT.BAT
	echo -e -n 'ECHO | SET /P="%rawfile%" > %TEMP%.\\SQ-WAVE.RAW\r\n' >> "$HOME"/AudioScope.tmp/VERT_BAT.BAT
	echo -e -n 'FOR /L %%n IN (1,1,13) DO TYPE %TEMP%.\\SQ-WAVE.RAW >> %TEMP%.\\SQ-WAVE.RAW\r\n' >> "$HOME"/AudioScope.tmp/VERT_BAT.BAT
	echo -e -n 'C:\\PROGRA~1\\SOX-14-4-1\\SOX -b 8 -r 8000 -e unsigned-integer -c 1 %TEMP%.\\SQ-WAVE.RAW -d\r\n' >> "$HOME"/AudioScope.tmp/VERT_BAT.BAT
	# Windows batch file SOX users end.
	printf "."

	# #########################################################
	# FOR SOund eXchance USERS ONLY!!!                TESTED!!!
	# The lines below, from ">" to the last "printf", will generate a new shell script...
	# Just EDIT out the comments and then EDIT the line pointing to the correct </full/path/to/sox/> to use it.
	# TRANSFER this file to another remote machine that has SOund eXchange, SOX, installed.
	# It assumes that you have SoX installed. When this script is run it generates a 1KHz squarewave on a remote computer
	# that lasts for 8 seconds. Just press ENTER when this window is active and it will repeat again.
	# To quit this script just press Ctrl-C. This generator will be needed for the vertical calibration.
	# Don't forget to chmod "VERT_SOX.sh" when copied onto the remote machine.
	: > "$HOME"/AudioScope.tmp/VERT_SOX.sh
	printf "%b" '#!/bin/bash\n' >> "$HOME"/AudioScope.tmp/VERT_SOX.sh
	printf "%b" ': > "$HOME"/AudioScope.tmp/squarewave.raw\n' >> "$HOME"/AudioScope.tmp/VERT_SOX.sh
	printf "%b" 'data="\\\\xFF\\\\xFF\\\\xFF\\\\xFF\\\\x00\\\\x00\\\\x00\\\\x00"\n' >> "$HOME"/AudioScope.tmp/VERT_SOX.sh
	printf "%b" 'for waveform in {0..8191}\n' >> "$HOME"/AudioScope.tmp/VERT_SOX.sh
	printf "%b" 'do\n' >> "$HOME"/AudioScope.tmp/VERT_SOX.sh
	printf "%b" '        printf "%b" "$data" >> "$HOME"/AudioScope.tmp/squarewave.raw\n' >> "$HOME"/AudioScope.tmp/VERT_SOX.sh
	printf "%b" 'done\n' >> "$HOME"/AudioScope.tmp/VERT_SOX.sh
	printf "%b" 'while true\n' >> "$HOME"/AudioScope.tmp/VERT_SOX.sh
	printf "%b" 'do\n' >> "$HOME"/AudioScope.tmp/VERT_SOX.sh
	printf "%b" '        /full/path/to/sox/play -b 8 -r 8000 -e unsigned-integer "$HOME"/AudioScope.tmp/squarewave.raw\n' >> "$HOME"/AudioScope.tmp/VERT_SOX.sh
	printf "%b" '        read -r -p "Press ENTER to rerun OR Ctrl-C to quit:- " -e kbinput\n' >> "$HOME"/AudioScope.tmp/VERT_SOX.sh
	printf "%b" 'done\n' >> "$HOME"/AudioScope.tmp/VERT_SOX.sh
	chmod 755 "$HOME"/AudioScope.tmp/VERT_SOX.sh
	# SOX users for *NIX flavours end.
	printf "."

	# #########################################################
	# FOR /dev/dsp USERS ONLY!!!                      TESTED!!!
	# The lines below, from ": >" to "chmod", will generate a new shell script...
	# Just EDIT out the comments to use it. TRANSFER this file to another machine that has the /dev/dsp device.
	# It assumes that you have /dev/dsp _installed_. When this script is run it generates a 1KHz squarewave on a remote computer
	# that lasts for 8 seconds. Just press ENTER when this window is active and it will repeat again.
	# To quit this script just press Ctrl-C. This generator will be needed for the vertical calibration.
	# Don't forget to chmod "VERT_DSP.sh" when copied onto the remote machine.
	: > "$HOME"/AudioScope.tmp/VERT_DSP.sh
	printf "%b" '#!/bin/bash\n' >> "$HOME"/AudioScope.tmp/VERT_DSP.sh
	printf "%b" ': > "$HOME"/AudioScope.tmp/squarewave.raw\n' >> "$HOME"/AudioScope.tmp/VERT_DSP.sh
	printf "%b" 'data="\\\\xFF\\\\xFF\\\\xFF\\\\xFF\\\\x00\\\\x00\\\\x00\\\\x00"\n' >> "$HOME"/AudioScope.tmp/VERT_DSP.sh
	printf "%b" 'for waveform in {0..8191}\n' >> "$HOME"/AudioScope.tmp/VERT_DSP.sh
	printf "%b" 'do\n' >> "$HOME"/AudioScope.tmp/VERT_DSP.sh
	printf "%b" '        printf "%b" "$data" >> "$HOME"/AudioScope.tmp/squarewave.raw\n' >> "$HOME"/AudioScope.tmp/VERT_DSP.sh
	printf "%b" 'done\n' >> "$HOME"/AudioScope.tmp/VERT_DSP.sh
	printf "%b" 'while true\n' >> "$HOME"/AudioScope.tmp/VERT_DSP.sh
	printf "%b" 'do\n' >> "$HOME"/AudioScope.tmp/VERT_DSP.sh
	printf "%b" '        cat "$HOME"/AudioScope.tmp/squarewave.raw > /dev/dsp\n' >> "$HOME"/AudioScope.tmp/VERT_DSP.sh
	printf "%b" '        read -r -p "Press ENTER to rerun OR Ctrl-C to quit:- " -e kbinput\n' >> "$HOME"/AudioScope.tmp/VERT_DSP.sh
	printf "%b" 'done\n' >> "$HOME"/AudioScope.tmp/VERT_DSP.sh
	chmod 755 "$HOME"/AudioScope.tmp/VERT_DSP.sh
	# DSP users for *NIX flavours end.
fi
printf ". DONE!"

# #########################################################
# Add the program title and version to the Terminal title bar...
# This may NOT work in every Terminal so just comment it out if it doesn't.
printf "%b" "\x1B]0;AudioScope Version ""$ver"".\x07"

# #########################################################
# A clear screen function that does NOT use "clear".
clrscn()
{
	printf "%b" "\x1B[2J\x1B[H"
}
# Use it to set up screen.
printf "%b" "\x1B[H\x1B[0;36;44m"
clrscn

# #########################################################
# A timing function that has keyboard override and does NOT use "sleep".
delay()
{
	read -r -n 1 -s -t "$1"
}

# #########################################################
# Create an independent Terminal for Apple OSX 10.12.x and above...
NewCLI()
{
	open -F -n -g -b com.apple.Terminal "$1"
}

# #########################################################
# Terminal reset command for CYGWIN that works for all...
reset()
{
	printf "%b" "\x1Bc\x1B[0m\x1B[2J\x1B[H"
}

# #########################################################
# This is setup for OSX 10.12.x minimum!
Enable_QT()
{
osascript << EnableQTP
	tell application "QuickTime Player"
		activate
		quit
	end tell
EnableQTP
# 'wait' added for fullness only.
wait
delay 1
}
#
QuickTime_Player()
{
# Use the Quicktime Player capture mode ENTIRELY AT YOUR OWN RISK!!!
# Using Quicktime Player as the sampling source.
# ************ OSX 10.7.x to 10.10.x ************
# This takes about 5 seconds per sample total and is for OSX 10.7.x...
# osascript << AppleSamplerOld
#	tell application "QuickTime Player"
#		set sample to (new audio recording)
#		set visible of front window to false
#		tell sample
#			delay 2
#			start
#			delay 2
#			stop
#		end tell
#		delay 1
#		quit
#	end tell
# AppleSamplerOld
# *************** OSX 10.7.x end. **************
# **************** OSX 10.12.x+ ****************
# This takes about 6 seconds per sample total and is for OSX 10.12.x, (and greater?)...
# Set "$HOME"/AudioScope.tmp/Untitled.m4a file to full R/W capability inside this function.
echo "" > "$HOME"/AudioScope.tmp/Untitled.m4a
chmod 666 "$HOME"/AudioScope.tmp/Untitled.m4a
osascript << AppleSampler
	tell application "QuickTime Player"
		activate
		set savePath to "Macintosh HD:Users:" & "$USER" & ":AudioScope.tmp:" & "Untitled.m4a"
		set recording to new audio recording
		set visible of front window to false
		delay 2
		start recording
		delay 2
		stop recording
		export document "Untitled" in file savePath using settings preset "Audio Only"
		close (every document whose name contains "Untitled") saving no
		tell application "System Events" to click menu item "Hide Export Progress" of menu "Window" of menu bar 1 of process "QuickTime Player"
		delay 1
		quit
	end tell
AppleSampler
# ************** OSX 10.12.x+ end. *************
# Hold until Quicktime fully closes down...
wait
delay 1
}

# #########################################################
# Windows Sound Recorder for use with CygWin(64).
# Use SoundRecorder.exe capture mode ENTIRELY AT YOUR OWN RISK!!!
WinSoundRecorder()
{
	cd "$HOME"/AudioScope.tmp
	SoundRecorder.exe \/FILE waveform.wav \/DURATION 0000:00:02
	cd "$HOME"
}

# #########################################################
# Generate a config file and temporarily store inside "$HOME"/AudioScope.tmp
if [ -f "$HOME"/AudioScope.Config ]
then
	. "$HOME"/AudioScope.Config
else
	user_config
fi
user_config()
{
	: > "$HOME"/AudioScope.Config
	chmod 644 "$HOME"/AudioScope.Config
	printf "%b" "demo=$demo\n" >> "$HOME"/AudioScope.Config
	printf "%b" "drawline=$drawline\n" >> "$HOME"/AudioScope.Config
	printf "%b" "sound_card_zero_offset=$sound_card_zero_offset\n" >> "$HOME"/AudioScope.Config
	printf "%b" "scan_start=$scan_start\n" >> "$HOME"/AudioScope.Config
	printf "%b" "scan_jump=$scan_jump\n" >> "$HOME"/AudioScope.Config
	printf "%b" "scan_end=$scan_end\n" >> "$HOME"/AudioScope.Config
	printf "%b" "scanloops=$scanloops\n" >> "$HOME"/AudioScope.Config
	printf "%b" "setup='$setup'\n" >> "$HOME"/AudioScope.Config
	printf "%b" "save_string='$save_string'\n" >> "$HOME"/AudioScope.Config
	printf "%b" "foreground=$foreground\n" >> "$HOME"/AudioScope.Config
	printf "%b" "timebase='$timebase'\n" >> "$HOME"/AudioScope.Config
	printf "%b" "polarity=$polarity\n" >> "$HOME"/AudioScope.Config
	printf "%b" "capturemode='$capturemode'\n" >> "$HOME"/AudioScope.Config
	printf "%b" "capturepath='$capturepath'\n" >> "$HOME"/AudioScope.Config
}

# #########################################################
# Screen display setup function. For a terminal size of 80 x 24.
display()
{
	# Set foreground and background graticule colours and foreground and background other window colours.
	printf "%b" "\x1B[H\x1B[0;36;44m       +-------+-------+-------+---[\x1B[1;37;44mDISPLAY\x1B[0;36;44m]---+-------+-------+--------+       \n"
	printf "%b" "       |       |       |       |       +       |       |       |        | \x1B[1;31;44mMAX\x1B[0;36;44m   \n"
	printf "%b" "       |       |       |       |       +       |       |       |        |       \n"
	printf "%b" "       |       |       |       |       +       |       |       |        |       \n"
	printf "%b" "     \x1B[1;31;44m+\x1B[0;36;44m +-------+-------+-------+-------+-------+-------+-------+--------+       \n"
	printf "%b" "       |       |       |       |       +       |       |       |        |       \n"
	printf "%b" "       |       |       |       |       +       |       |       |        |       \n"
	printf "%b" "       |       |       |       |       +       |       |       |        |       \n"
	printf "%b" "     \x1B[1;32;44m0\x1B[0;36;44m +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+--+ \x1B[1;32;44mREF\x1B[0;36;44m   \n"
	printf "%b" "       |       |       |       |       +       |       |       |        |       \n"
	printf "%b" "       |       |       |       |       +       |       |       |        |       \n"
	printf "%b" "       |       |       |       |       +       |       |       |        |       \n"
	printf "%b" "     \x1B[1;30;44m-\x1B[0;36;44m +-------+-------+-------+-------+-------+-------+-------+--------+       \n"
	printf "%b" "       |       |       |       |       +       |       |       |        |       \n"
	printf "%b" "       |       |       |       |       +       |       |       |        |       \n"
	printf "%b" "       |       |       |       |       +       |       |       |        |       \n"
	printf "%b" "       |       |       |       |       +       |       |       |        | \x1B[1;30;44mMIN\x1B[0;36;44m   \n"
	printf "%b" "       +-------+-------+-------[\x1B[1;37;44m    DC VOLTS   \x1B[0;36;44m]-------+-------+--------+       \n"
	printf "%b" " \x1B[0;37;40m+-----------------------------[\x1B[1;33;40mCOMMAND  WINDOW\x1B[0;37;40m]------------------------------+\x1B[0;37;44m \n"
	printf "%b" " \x1B[0;37;40m| COMMAND:-                                                                  |\x1B[0;37;44m \n"
	printf "%b" " \x1B[0;37;40m+------------------------------[\x1B[1;35;40mSTATUS WINDOW\x1B[0;37;40m]-------------------------------+\x1B[0;37;44m \n"
	printf "%b" " \x1B[0;37;40m| \x1B[0;$foreground;40mStopped...\x1B[0;37;40m                                                                 |\x1B[0;37;44m \n"
	printf "%b" " \x1B[0;37;40m|$setup|\x1B[0;37;44m \n"
	printf "%b" " \x1B[0;37;40m+---------------------------------[\x1B[1;37;40mCOUNTER\x1B[0;37;40m]----------------------------------+\x1B[0;37;44m \x1B[1;37;44m"
	# Set the colours for plotting.
}

# #########################################################
# Pick which method to capture, (and store), the waveform on the fly.
waveform()
{
	: > "$HOME"/AudioScope.tmp/waveform.raw
	chmod 644 "$HOME"/AudioScope.tmp/waveform.raw
	# Demo mode, generate 48000 bytes of random data.
	if [ $demo -eq 0 ]
	then
		# Use "delay" to simulate a 1 second burst.
		delay 1
		# "/dev/urandom is now used instead of RANDOM as it is MUCH faster.
		dd if=/dev/urandom of="$HOME"/AudioScope.tmp/waveform.raw bs=1 count=48000 > /dev/null 2>&1
	fi
	# Using the aging(/old) /dev/dsp device, mono, 8 bits per sample and 8KHz sampling rate, 8000 unsigned-integer bytes of data...
	# Now tested on PCLinuxOS 2009 and Debian 6.0.x.
	if [ $demo -eq 1 ]
	then
		# This uses the oss-compat installation from your distro's repository...
		dd if=/dev/dsp of="$HOME"/AudioScope.tmp/waveform.raw bs=1 count=12000 > /dev/null 2>&1
		dd if="$HOME"/AudioScope.tmp/waveform.raw of="$HOME"/AudioScope.tmp/sample.raw skip=4000 bs=1 count=8000 > /dev/null 2>&1
		cp "$HOME"/AudioScope.tmp/sample.raw "$HOME"/AudioScope.tmp/waveform.raw
	fi
	# The main means of obtaining the unsigned-integer data, using SoX, (Sound eXcahnge)...
	if [ $demo -eq 2 ]
	then
		# The absolute address will be found when running the code, but, it WILL take a LONG time to find...
		"$capturepath" -q -V0 -d -t raw -r 48000 -b 8 -c 1 -e unsigned-integer -> "$HOME"/AudioScope.tmp/waveform.raw trim 0 00:01
	fi
	# Using Quicktime for the MBP only. Each sample will take about 6 seconds.
	if [ $demo -eq 3 ]
	then
		# ************* OSX 10.7.x version. *************
		# Clear the default directory of ALL *.aifc files OSX 10.7.x!
		# rm "$HOME"/Movies/*.aifc > /dev/null 2>&1
		# Capture the signal.
		# QuickTime_Player > /dev/null 2>&1
		# Use the default converter to convert to a WAVE file for further manipulation OSX 10.7.x.
		# afconvert -f 'WAVE' -c 1 -d UI8@48000 "$HOME/Movies/Audio Recording.aifc" "$HOME"/AudioScope.tmp/waveform.wav
		# *************** OSX 10.7.x end. ***************
		# ************* OSX 10.12.x version. ************
		# Delete "$HOME"/AudioScope.tmp/Untitled/m4a OSX 10.12.x!
		rm "$HOME"/AudioScope.tmp/Untitled.m4a
		# Capture the signal.
		QuickTime_Player > /dev/null 2>&1
		# Use the default converter to convert to a WAVE file for further manipulation OSX 10.12.x.
		afconvert -f 'WAVE' -c 1 -d UI8@48000 "$HOME"/AudioScope.tmp/Untitled.m4a "$HOME"/AudioScope.tmp/waveform.wav
		# ************** OSX 10.12.x end. ***************
		# Convert to a RAW file format for displaying.
		dd if="$HOME"/AudioScope.tmp/waveform.wav of="$HOME"/AudioScope.tmp/waveform.raw skip=4096 bs=1 count=48000 > /dev/null 2>&1
	fi
	# Using Windows SoundRecorder.exe for an alternative CygWin capture. Each sample will take about 5 seconds.
	if [ $demo -eq 4 ]
	then
		# Capture an approximately 2 second burst *.WAV file for further manipulation.
		WinSoundRecorder
		# Strip the WAVE header and obtain 48000 * 4 bytes of stereo CD standard data.
		dd if="$HOME"/AudioScope.tmp/waveform.wav of="$HOME"/AudioScope.tmp/sample.raw skip=4096 bs=1 count=192000 > /dev/null 2>&1
		# Convert all this data to the equivalent of 16 bit signed decimal text file.
		od -td2 -An "$HOME"/AudioScope.tmp/sample.raw > "$HOME"/AudioScope.tmp/signed16bit.txt
		# This 'awk' script converts signed '16 bit' decimal to unsigned '8 bit' decimal 48000 bytes in size.
		# Tested on two machines with CygWin installed.
		# Note that the sample rate is 44100Hz and the calibrated timebase ranges altered to suit for this mode.
		awk --characters-as-bytes '
		{
			BINMODE=3;
			FS=" ";
		}
		{
			if ($1=="") exit(0);
			$1=(int(($1+32768)/256));
			$3=(int(($3+32768)/256));
			$5=(int(($5+32768)/256));
			$7=(int(($7+32768)/256));
			printf("%c%c%c%c",$1,$3,$5,$7);
		}' < "$HOME"/AudioScope.tmp/signed16bit.txt > "$HOME"/AudioScope.tmp/waveform.raw
	fi
	# This is for Linux ALSA users that has 'arecord' as a capture source.
	if [ $demo -eq 5 ]
	then
		arecord -d 1 -c 1 -f U8 -r 48000 -t raw "$HOME"/AudioScope.tmp/waveform.raw > /dev/null 2>&1
	fi
}

# #########################################################
# Plot the points inside the window...
plot()
{
	subscript=$scan_start
	vert_array=""
	for horiz in {9..72}
	do
		if [ "${u_name:0:6}" != "CYGWIN" ]
		then
			vert=$( hexdump -n1 -s$subscript -v -e '1/1 "%u"' "$HOME"/AudioScope.tmp/waveform.raw )
		else
			# CYGWIN mode.
			vert=$( od -An -N1 -j$subscript -tu1 "$HOME"/AudioScope.tmp/waveform.raw )
		fi
		# This inverts the waveform so as to display it correctly on screen.
		if [ $polarity -eq 1 ]
		then
			vert=$(( 255 - $vert ))
		fi
		# Add a small offset to give a straight line with zero input allowing for mid-point sound card bit error.
		vert=$(( $vert + $sound_card_zero_offset ))
		if [ $vert -le 0 ]
		then
			vert=0
		fi
		if [ $vert -ge 255 ]
		then
			vert=255
		fi
		# Pseudo-vertical shift of + or - 1 vertical division maximum.
		vert=$(( ( $vert / 16 ) + $vert_shift ))
		# Ensure the plot is NOT out of bounds after moving the shift position.
		if [ $vert -le 2 ]
		then
			vert=2
		fi
		if [ $vert -ge 17 ]
		then
			vert=17
		fi
		subscript=$(( $subscript + $scan_jump ))
		# Generate a simple space delimited 64 sample array.
		vert_array="$vert_array$vert "
		printf "%b" "\x1B[1;37;44m\x1B[""$vert"";""$horiz""f*"
	done
	# Set end of plot to COMMAND window.
	printf "%b" "\x1B[0;37;40m\x1B[20;14f"
}

# #########################################################
# This function connects up the plotted points.
# Defaults to OFF on the very first time run and must be manually enabled if needed.
draw()
{
	statusline
	IFS=" "
	subscript=0
	number=0
	vert_one=2
	vert_two=2
	vert_draw=( $vert_array )
	for horiz in {9..71}
	do
		# Obtain the two vertical components.
		vert_one=${vert_draw[$subscript]}
		subscript=$(( $subscript + 1 ))
		vert_two=${vert_draw[$subscript]}
		# Now subtract them and obtain an absolute value - ALWAYS 0 to positive...
		number=$(( $vert_two - $vert_one ))
		number=${number#-}
		# This decision section _is_ needed.
		if [ $number -le 1 ]
		then
			: # NOP. Do nothing...
		fi
		# This section does the drawing...
		if [ $number -ge 2 ]
		then
			if [ $vert_one -gt $vert_two ]
			then
				vert_one=$(( $vert_one - 1 ))
				while [ $vert_one -gt $vert_two ]
				do
					printf "%b" "\x1B[1;37;44m\x1B[""$vert_one"";""$horiz""f*"
					vert_one=$(( $vert_one - 1 ))
				done
			fi
			if [ $vert_two -gt $vert_one ]
			then
				vert_one=$(( $vert_one + 1 ))
				while [ $vert_one -lt $vert_two ]
				do
					printf "%b" "\x1B[1;37;44m\x1B[""$vert_one"";""$horiz""f*"
					vert_one=$(( $vert_one + 1 ))
				done
			fi
		fi
	done
	IFS="$ifs_str"
	# Set end of plot to COMMAND window.
	printf "%b" "\x1B[0;37;40m\x1B[20;14f"
}

# #########################################################
# This is the information line _parser_...
statusline()
{
	printf "%b" "\x1B[0;37;40m\x1B[22;3f$blankline\x1B[22;4f"
	if [ $status -eq 0 ]
	then
		printf "%b" "\x1B[0;$foreground;40mStopped...\x1B[0;37;40m"
	fi
	if [ $status -eq 1 ]
	then
		printf "%b" "Running \x1B[0;32;40m$scan\x1B[0;37;40m of \x1B[0;32;40m$scanloops\x1B[0;37;40m scan(s)..."
	fi
	if [ $status -eq 2 ]
	then
		printf "%b" "\x1B[0;33;40mRunning in single shot storage mode...\x1B[0;37;40m"
	fi
	if [ $status -eq 3 ]
	then
		printf "%b" "\x1B[0;33;40mDrawing the scan...\x1B[0;37;40m"
	fi
	if [ $status -eq 4 ]
	then
		printf "%b" "Synchronisation set to \x1B[0;32;40m$sync_point\x1B[0;37;40m$synchronise..."
	fi
	if [ $status -eq 5 ]
	then
		printf "%b" "\x1B[1;31;40mCAUTION, AUTO-SAVING FACILITY ENABLED!!!\x1B[0;37;40m"
	fi
	if [ $status -eq 6 ]
	then
		printf "%b" "\x1B[0;33;40m$zoom\x1B[0;37;40m"
	fi
	if [ $status -eq 7 ]
	then
		printf "%b" "Horizontal shift, scan start at position \x1B[0;32;40m$scan_start\x1B[0;37;40m..."
	fi
	if [ $status -eq 8 ]
	then
		printf "%b" "Symmetrical waveform frequency is \x1B[0;32;40m"$freq"\x1B[0;37;40m Hz..."
	fi
	if [ $status -eq 9 ]
	then
		printf "%b" "X=\x1B[0;33;40m166.7uS/DIV\x1B[037;40m for DEMO, SOX, ALSA or QTMAC, \x1B[0;33;40m1mS/DIV\x1B[037;40m for DSP."
	fi
	if [ $status -eq 10 ]
	then
		printf "%b" "$char"
	fi
	if [ $status -eq 11 ]
	then
		printf "%b" "\x1B[1;31;40m!!!WARNING!!! YOU USE THIS MODE ENTIRELY AT YOUR OWN RISK!\x1B[0;37;40m"
	fi
	if [ $status -eq 254 ]
	then
		status=1
		printf "%b" "\x1B[23;3f$version\x1B[20;14f"
		delay 2
	fi
	# Set end of plot to COMMAND window.
	printf "%b" "\x1B[0;37;40m\x1B[20;14f"
}

# #########################################################
# All keyboard commands appear here when the scanning stops; there will be lots of them to make subtle changes...
# I have forced the use of UPPERCASE for the vast majority of the commands, so be aware!
# Incorrect commands are ignored and just reruns the scan and returns back to the COMMAND mode...
kbcommands()
{
	IFS="$ifs_str"
	status=1
	read -r -p "Press <CR> to (re)run, HELP or QUIT<CR>:- " -e kbinput
	printf "%b" "\x1B[0;37;40m\x1B[20;14f                                                                 \x1B[20;14f"
	# Rerun scans captured or stored.
	if [ "$kbinput" == "" ]
	then
		status=1
		statusline
	fi
	# Run scans in captured, (REAL scan), mode only.
	if [ "$kbinput" == "RUN" ]
	then
		status=1
		hold=1
		statusline
	fi
	# Full exit without saving the AudioScope.* files.
	if [ "$kbinput" == "EXIT" ]
	then
		# Reset the terminal size.
		vert=${term_size[0]}
		horiz=${term_size[1]}
		printf "%b" "\x1B[8;"$vert";"$horiz"t"
		# Remove "Shell AudioScope" from the title bar.
		printf "%b" "\x1B]0;\x07"
		# Do a complete terminal reset.
		reset
		echo ""
		echo "Reset the terminal without saving any files!"
		echo ""
		exit 0
	fi
	# Quit the program.
	if [ "$kbinput" == "QUIT" ]
	then
		status=255
		return 10
	fi
	# Switch off capture mode and rerun one storage shot only, this disables the DRAW command.
	# Use DRAW to re-enable again. This is deliberate for slow machines...
	if [ "$kbinput" == "HOLD" ]
	then
		hold=0
		drawline=0
		status=2
		scanloops=1
		coupling="AC"
		statusline
		delay 1
	fi
	# Display the _online_ HELP file in default terminal colours.
	if [ "$kbinput" == "HELP" ]
	then
		status=0
		scanloops=1
		hold=0
		coupling="AC"
		commandhelp
	fi
	# Enable DEMO pseudo-capture mode, default, but with 10 sweeps...
	if [ "$kbinput" == "DEMO" ]
	then
		status=1
		scan_start=1024
		scan_jump=1
		scanloops=10
		scan_end=47930
		hold=1
		demo=0
		dc_flag=0
		capturemode="DEMO"
		timebase="Fastest possible"
		coupling="AC"
		statusline
		delay 1
	fi
	# Enable /dev/dsp capture mode, if your Linux flavour does NOT have it, install oss-compat from the distro's repository.
	# This is the mode used to test on Debian 6.0.x and now PCLinuxOS 2009...
	if [ "$kbinput" == "DSP" ]
	then
		capturepath=$( ls /dev/dsp 2>/dev/null )
		status=1
		scan_start=1024
		scan_jump=1
		scanloops=1
		scan_end=7930
		hold=1
		demo=1
		dc_flag=0
		capturemode="DSP"
		timebase="Fastest possible"
		coupling="AC"
		if [ "$capturepath" == "" ]
		then
			printf "%b" "\x1B[0;31;40m\x1B[22;3f$blankline\x1B[22;4fThe device /dev/dsp does not exist, switching back to DEMO mode...\x1B[20;14f"
			delay 3
			capturepath=$device
			scan_end=47930
			demo=0
			capturemode="DEMO"
		fi
		statusline
		delay 1
	fi
	# Enable SOX capture mode, this code is designed around this application on a Macbook Pro 13 inch OSX 10.7.5...
	# This is the main capture method and SoX WILL need to be installed for FULL real usage.
	if [ "$kbinput" == "SOX" ]
	then
		printf "%b" "\x1B[0;37;40m\x1B[22;3f$blankline\x1B[22;4fPlease wait while SOX is found, this \x1B[0;31;40mMIGHT\x1B[0;37;40m take a \x1B[0;31;40mLONG\x1B[0;37;40m time...\x1B[20;14f"
		# Auto-find the correct path and "sox" file, but it WILL take a very long time...
		# NOTE: It searches from YOUR HOME directory structure only, just modify to suit your machine if 'SOX' is elsewhere.
		capturepath=$( find "$HOME" -type d -name '.?*' -prune -o -type f -name 'sox' -print 2>/dev/null )
		# Some Linux flavours have sox installed in the '/usr/bin' folder/drawer/directory.
		char=$( which sox 2>/dev/null )
		if [ "$char" != "" ]
		then
			capturepath="$char"
		fi
		status=1
		scan_start=1024
		scan_jump=1
		scanloops=1
		scan_end=47930
		hold=1
		demo=2
		dc_flag=0
		capturemode="SOX"
		timebase="Fastest possible"
		coupling="AC"
		if [ "$capturepath" == "" ]
		then
			printf "%b" "\x1B[0;31;40m\x1B[22;3f$blankline\x1B[22;4fThe SOX audio device was not found, switching back to DEMO mode...\x1B[20;14f"
			delay 3
			capturepath=$device
			demo=0
			capturemode="DEMO"
		fi
		statusline
		delay 1
	fi
	# This is a command to switch the sampling source on this machine, (MBP, OSX 10.7.x), to Quicktime using AppleScript.
	# It is SLOW but works and the sample speed for the resultant grab is still 48000 bytes per second.
	# This is so as to make this code Apple MacBook Pro specific. It might work on other MAC units and
	# later versions of OSX but it is not guaranteed, so be very aware!
	if [ "$kbinput" == "QTMAC" ]
	then
		capturepath=$( ls /usr/bin/osascript 2>/dev/null )
		status=11
		scan_start=1024
		scan_jump=1
		scanloops=1
		scan_end=47930
		hold=1
		demo=3
		dc_flag=0
		capturemode="MAC"
		timebase="Fastest possible"
		coupling="AC"
		if [ "$capturepath" == "" ]
		then
			printf "%b" "\x1B[0;31;40m\x1B[22;3f$blankline\x1B[22;4fThe MAC audio device was not found, switching back to DEMO mode...\x1B[20;14f"
			delay 3
			capturepath=$device
			demo=0
			capturemode="DEMO"
			status=1
		else
			printf "%b" "\x1B[0;32;40m\x1B[22;3f$blankline\x1B[22;4fEnabling Quicktime Player...\x1B[20;14f"
			Enable_QT > /dev/null 2>&1
			wait
			delay 1
		fi
		statusline
		delay 1
	fi
	# This is a command to switch the sampling source, (Windows Vista and above), to SoundRecorder.exe for CygWin.
	# It is SLOW but works and the sample speed for the resultant grab is 44100 bytes per second. This is not changeable as
	# a default OEM Windows install does not have tools to change the parameters from the CD standard .WAV format to any other.
	if [ "$kbinput" == "WINSOUND" ]
	then
		capturepath=$( SoundRecorder.exe \/FILE waveform.wav \/DURATION 0000:00:02 > /dev/null 2>&1 )
		number="$?"
		status=11
		scan_start=1024
		scan_jump=1
		scanloops=1
		scan_end=47930
		hold=1
		demo=4
		dc_flag=0
		capturemode="CYGWIN"
		timebase="Fastest possible"
		coupling="AC"
		if [ $number -gt 0 ]
		then
			printf "%b" "\x1B[0;31;40m\x1B[22;3f$blankline\x1B[22;4fThe Windows audio device was not found, switching back to DEMO mode...\x1B[20;14f"
			delay 3
			capturepath=$device
			demo=0
			capturemode="DEMO"
			status=1
		fi
		statusline
		delay 1
	fi
	# This is a command to switch the sampling source, (Linux ALSA sound systems), to 'arecord' capture mode.
	if [ "$kbinput" == "ALSA" ]
	then
		capturepath=$( ls /usr/bin/arecord 2>/dev/null )
		status=11
		scan_start=1024
		scan_jump=1
		scanloops=1
		scan_end=47930
		hold=1
		demo=5
		dc_flag=0
		capturemode="ALSA"
		timebase="Fastest possible"
		coupling="AC"
		if [ "$capturepath" == "" ]
		then
			printf "%b" "\x1B[0;31;40m\x1B[22;3f$blankline\x1B[22;4fThe ALSA audio device was not found, switching back to DEMO mode...\x1B[20;14f"
			delay 3
			capturepath=$device
			demo=0
			capturemode="DEMO"
			status=1
		fi
		statusline
		delay 1
	fi
	# The next three commands set the timebase scans; 1, 10 or 100 before COMMAND mode is re-enabled and can be used.
	if [ "$kbinput" == "ONE" ]
	then
		status=1
		scanloops=1
		hold=1
	fi
	if [ "$kbinput" == "TEN" ]
	then
		status=1
		scanloops=10
		hold=1
	fi
	if [ "$kbinput" == "HUNDRED" ]
	then
		status=1
		scanloops=100
		hold=1
	fi
	# This just ptints the version and author of this project.
	if [ "$kbinput" == "VER" ]
	then
		scanloops=1
		status=254
	fi
	# ************ Horizontal components. *************
	# ************ User timebase section. *************
	# Written longhand for kids to understand.
	if [ "$kbinput" == "TBVAR" ]
	then
		# Ensure capture mode is turned off.
		# RUN<CR> will re-enable it if required.
		scanloops=1
		status=1
		hold=0
		coupling="AC"
		timebase="User variable"
		printf "%b" "\x1B[0;37;40m\x1B[20;14f"
		read -r -p "Set timebase starting point. From 0 to $scan_end<CR> " -e tbinput
		printf "%b" "\x1B[0;37;40m\x1B[20;14f                                                                 \x1B[0;37;40m\x1B[20;14f"
		# Ensure the timebase values are set to default before changing.
		scan_start=0
		scan_jump=1
		# Eliminate any keyboard error longhand...
		# Ensure a NULL string does NOT exist.
		if [ "$tbinput" == "" ]
		then
			scan_start=0
			tbinput=0
		fi
		# Find the length of the inputted string and correct for subscript position.
		str_len=$(( ${#tbinput} - 1 ))
		# Now check for continuous numerical characters ONLY.
		for count in $( seq 0 $str_len )
		do
			# Reuse variable _number_ to obtain each character per loop.
			number=${tbinput:$count:1}
			# Now convert the character to a decimal number.
			number=$( printf "%d" "'$number " )
			# IF ANY ASCII character exists that is not numerical then reset the scan start point.
			if [ $number -le 47 ]
			then
				scan_start=0
				tbinput=0
			fi
			if [ $number -ge 58 ]
			then
				scan_start=0
				tbinput=0
			fi
		done
		if [ "${tbinput}" -ge "2" ]
		then
			tbinput=${tbinput#${tbinput%%[1-9-]*}}
		fi
		# If all is OK pass the "tbinput" value into the "scan_start" variable.
		scan_start=$tbinput
		# Do a final check that the number is not out of bounds.
		if [ $scan_start -le 0 ]
		then
			scan_start=0
		fi
		if [ $scan_start -ge $scan_end ]
		then
			scan_start=$scan_end
		fi
		# Use exactly the same method as above to determine the jump interval.
		# Now set the jump interval, this is the scan speed...
		printf "%b" "\x1B[0;37;40m\x1B[20;14f"
		read -r -p "Set timebase user speed. From 1 to $(( ( ( $scan_end - $scan_start ) / 64 ) + 1 ))<CR> " -e tbinput
		printf "%b" "\x1B[0;37;40m\x1B[20;14f                                                                 \x1B[0;37;40m\x1B[20;14f"
		# Eliminate any keyboard error longhand...
		# Ensure a NULL string does NOT exist.
		if [ "$tbinput" == "" ]
		then
			scan_jump=1
			tbinput=1
		fi
		# Find the length of the inputted string and correct for subscript position.
		str_len=$(( ${#tbinput} - 1 ))
		# Now check for continuous numerical characters ONLY.
		for count in $( seq 0 $str_len )
		do
			# Reuse variable _number_ to obtain each character per loop.
			number=${tbinput:$count:1}
			# Now convert the character to a decimal number.
			number=$( printf "%d" "'$number " )
			# IF ANY ASCII character exists that is not numerical then reset the scan jump value.
			if [ $number -le 47 ]
			then
				scan_jump=1
				tbinput=1
			fi
			if [ $number -ge 58 ]
			then
				scan_jump=1
				tbinput=1
			fi
		done
		if [ "${tbinput}" -ge "2" ]
		then
			tbinput=${tbinput#${tbinput%%[1-9-]*}}
		fi
		# If all is OK pass the "tbinput" value into the "scan_jump" variable.
		scan_jump=$tbinput
		# Do a final check that the number is not out of bounds.
		if [ $scan_jump -le 1 ]
		then
			scan_jump=1
		fi
		# Reuse number for upper limit...
		number=$(( ( ( $scan_end - $scan_start ) / 64 ) + 1 ))
		if [ $scan_jump -ge $number ]
		then
			scan_jump=$number
		fi
		printf "%b" "\x1B[0;37;40m\x1B[22;4fScan start at offset \x1B[0;32;40m$scan_start\x1B[0;37;40m, with a jump rate of \x1B[0;32;40m$scan_jump\x1B[0;37;40m."
		delay 2
	fi
	# ********** User timebase section end. ***********
	# ********* Calibrated timebase section. **********
	if [ "$kbinput" == "FASTEST" ]
	then
		scan_start=1024
		scan_jump=1
		scanloops=1
		hold=0
		coupling="AC"
		timebase="Fastest possible"
		status=9
		statusline
		delay 2
	fi
	if [ "$kbinput" == "1mS" ]
	then
		scan_start=1024
		scanloops=1
		hold=0
		coupling="AC"
		timebase="1mS/DIV"
		status=1
		if [ $demo -eq 0 ] || [ $demo -eq 2 ] || [ $demo -eq 3 ] || [ $demo -eq 5 ]
		then
			scan_jump=6
		fi
		if [ $demo -eq 1 ]
		then
			scan_jump=1
		fi
		if [ $demo -eq 4 ]
		then
			scan_jump=5
		fi
	fi
	if [ "$kbinput" == "2mS" ]
	then
		scan_start=1024
		scanloops=1
		hold=0
		couplng="AC"
		timebase="2mS/DIV"
		status=1
		if [ $demo -eq 0 ] || [ $demo -eq 2 ] || [ $demo -eq 3 ] || [ $demo -eq 5 ]
		then
			scan_jump=12
		fi
		if [ $demo -eq 1 ]
		then
			scan_jump=2
		fi
		if [ $demo -eq 4 ]
		then
			scan_jump=11
		fi
	fi
	if [ "$kbinput" == "5mS" ]
	then
		scan_start=1024
		scanloops=1
		hold=0
		coupling="AC"
		timebase="5mS/DIV"
		status=1
		if [ $demo -eq 0 ] || [ $demo -eq 2 ] || [ $demo -eq 3 ] || [ $demo -eq 5 ]
		then
			scan_jump=30
		fi
		if [ $demo -eq 1 ]
		then
			scan_jump=5
		fi
		if [ $demo -eq 4 ]
		then
			scan_jump=28
		fi
	fi
	if [ "$kbinput" == "10mS" ]
	then
		scan_start=1024
		scanloops=1
		hold=0
		coupling="AC"
		timebase="10mS/DIV"
		status=1
		if [ $demo -eq 0 ] || [ $demo -eq 2 ] || [ $demo -eq 3 ] || [ $demo -eq 5 ]
		then
			scan_jump=60
		fi
		if [ $demo -eq 1 ]
		then
			scan_jump=10
		fi
		if [ $demo -eq 4 ]
		then
			scan_jump=55
		fi
	fi
	if [ "$kbinput" == "20mS" ]
	then
		scan_start=1024
		scanloops=1
		hold=0
		coupling="AC"
		timebase="20mS/DIV"
		status=1
		if [ $demo -eq 0 ] || [ $demo -eq 2 ] || [ $demo -eq 3 ] || [ $demo -eq 5 ]
		then
			scan_jump=120
		fi
		if [ $demo -eq 1 ]
		then
			scan_jump=20
		fi
		if [ $demo -eq 4 ]
		then
			scan_jump=110
		fi
	fi
	if [ "$kbinput" == "50mS" ]
	then
		scan_start=1024
		scanloops=1
		hold=0
		coupling="AC"
		timebase="50mS/DIV"
		status=1
		if [ $demo -eq 0 ] || [ $demo -eq 2 ] || [ $demo -eq 3 ] || [ $demo -eq 5 ]
		then
			scan_jump=300
		fi
		if [ $demo -eq 1 ]
		then
			scan_jump=50
		fi
		if [ $demo -eq 4 ]
		then
			scan_jump=275
		fi
	fi
	if [ "$kbinput" == "100mS" ]
	then
		scan_start=1024
		scanloops=1
		hold=0
		coupling="AC"
		timebase="100mS/DIV"
		status=1
		if [ $demo -eq 0 ] || [ $demo -eq 2 ] || [ $demo -eq 3 ] || [ $demo -eq 5 ]
		then
			scan_jump=600
		fi
		if [ $demo -eq 1 ]
		then
			scan_jump=100
		fi
		if [ $demo -eq 4 ]
		then
			scan_jump=551
		fi
	fi
	if [ "$kbinput" == "SLOWEST" ]
	then
		scan_start=0
		scanloops=1
		hold=0
		coupling="AC"
		timebase="Slowest possible"
		status=1
		if [ $demo -eq 1 ]
		then
			scan_jump=124
		else
			scan_jump=748
		fi
	fi
	# *********** Calibrated timebase end. ************
	#
	# ************* Vertical components. **************
	# ******** Pseudo-vertical shift control. *********
	if [ "$kbinput" == "VSHIFT" ]
	then
		while true
		do
			scanloops=1
			status=1
			hold=0
			coupling="AC"
			printf "%b" "\x1B[0;37;40m\x1B[20;14f"
			# This input method is something akin to BASIC's INKEY$...
			read -r -p "Vertical shift:- U for up 1, D for down 1, <CR> to RETURN:- " -n 1 -s vshift
			printf "%b" "\x1B[0;37;40m\x1B[20;14f                                                                 \x1B[0;37;40m\x1B[20;14f"
			if [ "$vshift" == "" ]
			then
				break
			fi
			if [ "$vshift" == "D" ]
			then
				vert_shift=$(( $vert_shift + 1 ))
			fi
			if [ "$vshift" == "U" ]
			then
				vert_shift=$(( $vert_shift - 1 ))
			# Ensure the shift psoition is NOT out of bounds.
			fi
			if [ $vert_shift -ge 6 ]
			then
				vert_shift=6
			fi
			if [ $vert_shift -le -2 ]
			then
				vert_shift=-2
			fi
			printf "%b" "\x1B[23;3f Vertical shift is \x1B[0;32;40m$(( 2 - $vert_shift ))\x1B[0;37;40m from the mid-point position...                        "
		done
	fi
	# ****** Pseudo-vertical shift control end. *******
	#
	# ***** Set the vertical volts per division. ******
	if [ "$kbinput" == "V" ]
	then
		char="?"
		vertical="Uncalibrated (m)V/DIV"
		for number in {1..18}
		do
			printf "%b" "\x1B[1;37;44m\x1B[$number;3f$blankline\x1B[H"
		done
		echo ""
		echo " This command sets the vertical Volts Per Division, (10mV), 100mV to 10V/DIV."
		echo " Ensure the hardware REQUIRED, (that is the vertical amplifier as a minimum),"
		echo " is connected. (If any DC attachment is used also then this is common to both.)"
		echo ""
		echo " 1) ENSURE ANY EXTERNAL HARDWARE REQUIRED IS CONNECTED!"
		echo ""
		echo " 2) Physically change the range on all the hardware connected to be the same."
		echo ""
		echo " 3) This is either (10mV), 100mV, 1V or 10V. Note that 10mV is only available"
		echo "    on machines with that microphone input sensitivity."
		echo ""
		echo " 4) Enter the range value below and the software will be set correctly to the"
		echo "    hardware range physically selected."
		printf "%b" "\x1B[0;37;40m\x1B[20;14f"
		read -r -p "Set (m)V/Div. (10mV), 100mV, 1V or 10V<CR> or <CR>:- " -e char
		printf "%b" "\x1B[0;37;40m\x1B[20;14f                                                                 \x1B[20;14f"
		if [ "$char" == "10mV" ]
		then
			vertical="10mV/DIV"
		fi
		if [ "$char" == "100mV" ]
		then
			vertical="100mV/DIV"
		fi
		if [ "$char" == "1V" ]
		then
			vertical="1V/DIV"
		fi
		if [ "$char" == "10V" ]
		then
			vertical="10V/DIV"
		fi
	fi
	# ******** End of vertical voltage range. *********
	#
	# ********** Connect all plotted points. **********
	if [ "$kbinput" == "DRAW" ]
	then
		drawline=1
		status=3
		hold=0
		coupling="AC"
		scanloops=1
		statusline
		delay 1
	fi
	# ************* Connected plots done. *************
	#
	# **** PSEUDO synchronisation and triggering. ****
	if [ "$kbinput" == "TRIG" ]
	then
		synchronise=" and OFF"
		sync_point=128
		status=0
		hold=0
		coupling="AC"
		scan_start=$(( $scan_start + 1 ))
		scan_jump=1
		scanloops=1
		subscript=$scan_start
		grab=0
		ext_trig_array=""
		count=0
		number=1
		char="+"
		if [ $scan_start -ge $scan_end ]
		then
			scan_start=0
			break
		fi
		printf "%b" "\x1B[0;37;40m\x1B[20;14f"
		read -r -p "Set trigger type, <CR> to disable:- " -e kbinput
		printf "%b" "\x1B[0;37;40m\x1B[20;14f                                                                 \x1B[0;37;40m\x1B[20;14f"
		if [ "$kbinput" == "SYNCEQ" ]
		then
			synchronise=", ON and fixed"
			trigger
			for subscript in $( seq $scan_start $scan_end )
			do
				if [ "${u_name:0:6}" != "CYGWIN" ]
				then
					grab=$( hexdump -n1 -s$subscript -v -e '1/1 "%u"' "$HOME"/AudioScope.tmp/waveform.raw )
				else
					# CYGWIN mode.
					grab=$( od -An -N1 -j$subscript -tu1 "$HOME"/AudioScope.tmp/waveform.raw )
				fi
				if [ $grab -eq $sync_point ]
				then
					scan_start=$subscript
					break
				fi
			done
		fi
		if [ "$kbinput" == "SYNCGT" ]
		then
			synchronise=", ON and positive going"
			for subscript in $( seq $scan_start $scan_end )
			do
				if [ "${u_name:0:6}" != "CYGWIN" ]
				then
					grab=$( hexdump -n1 -s$subscript -v -e '1/1 "%u"' "$HOME"/AudioScope.tmp/waveform.raw )
				else
					# CYGWIN mode.
					grab=$( od -An -N1 -j$subscript -tu1 "$HOME"/AudioScope.tmp/waveform.raw )
				fi
				if [ $grab -lt 128 ]
				then
					scan_start=$subscript
					break
				fi
			done
		fi
		if [ "$kbinput" == "SYNCLT" ]
		then
			synchronise=", ON and negative going"
			for subscript in $( seq $scan_start $scan_end )
			do
				if [ "${u_name:0:6}" != "CYGWIN" ]
				then
					grab=$( hexdump -n1 -s$subscript -v -e '1/1 "%u"' "$HOME"/AudioScope.tmp/waveform.raw )
				else
					# CYGWIN mode.
					grab=$( od -An -N1 -j$subscript -tu1 "$HOME"/AudioScope.tmp/waveform.raw )
				fi
				if [ $grab -gt 128 ]
				then
					scan_start=$subscript
					break
				fi
			done
		fi
		# Pseudo-external triggering ONLY works with SOX installed!
		# IMPORTANT! ENSURE A SIGNAL IS PRESENT ON THE CAPTURE INPUT!
		if [ "$kbinput" == "EXT" ] && [ "$capturemode" == "SOX" ] && [ "${u_name:0:6}" != "CYGWIN" ]
		then
			drawline=1
			# Enable real capture mode.
			hold=1
			status=4
			synchronise=", EXTERNAL and waiting"
			# Remember Corona688's code from the early stages of this thread...
			display
			printf "%b" "\x1B[0;37;40m\x1B[20;14f"
			read -r -p "Set trigger polarity, +, - or <CR>:- " -e char
			printf "%b" "\x1B[0;37;40m\x1B[20;14f                                                                 \x1B[0;37;40m\x1B[20;14f"
			trigger
			statusline
			printf "%b" "\x1B[23;3f$setup"
			# Ensure trigger is positive OR negative going but if there is an error then force positive going.
			if [ "$char" == "+" ] || [ "$char" == "-" ]
			then
				statusline
			else
				char="+"
			fi
			# Ensure an exit from the loop is possible...
			Ctrl_C()
			{
				number=0
			}
			# Continually loop until the correct FIXED value is found.
			while [ $number -eq 1 ]
			do
				# Do a lo-res capture to start the master capture off.
				$capturepath -q -V0 -d -t raw -r 8000 -b 8 -c 1 -e unsigned-integer -> "$HOME"/AudioScope.tmp/waveform.raw trim 0 00:01
				trap Ctrl_C SIGINT
				printf "%b" "\x1B[0;32;40m\x1B[20;20f( Press Ctrl-C to exit if needed, \x1B[0;31;40mNOW!\x1B[0;32;40m )\x1B[0;37;40m\x1B[20;14f"
				ext_trig_array=($( hexdump -v -e '1/1 "%u "' "$HOME"/AudioScope.tmp/waveform.raw ))
				# Find the FIRST fixed trigger value and then exit the loop.
				for count in {0..7998}
				do
					if [ "$char" == "+" ]
					then
						if [ ${ext_trig_array[$count]} -eq $sync_point ] && [ ${ext_trig_array[$(( $count + 1 ))]} -gt $sync_point ]
						then
							break 2
						fi
					fi
					if [ "$char" == "-" ]
					then
						if [ ${ext_trig_array[$count]} -eq $sync_point ] && [ ${ext_trig_array[$(( $count + 1 ))]} -lt $sync_point ]
						then
							break 2
						fi
					fi
				done
				printf "%b" "\x1B[0;37;40m\x1B[20;14f                                                                 \x1B[0;37;40m\x1B[20;14f"
			done
			# On exiting the loop follow on with a full scan.
			$capturepath -q -V0 -d -t raw -r 48000 -b 8 -c 1 -e unsigned-integer -> "$HOME"/AudioScope.tmp/waveform.raw trim 0 00:01
			trap - SIGINT
			# And finally ensure that real capture mode is switched to storage mode.
			hold=0
		fi
	fi
	# ** PSEUDO synchronisation and triggering end. ***
	#
	# ******** Manual and Auto-saving facility. *******
	if [ "$kbinput" == "SAVE" ]
	then
		hold=1
		scanloops=1
		status=0
		save_string="OFF"
		savefile=$( date +%s )'.BIN'
		cp "$HOME"/AudioScope.tmp/waveform.raw "$HOME"/AudioScope.tmp/"$savefile"
		statusline
	fi
	if [ "$kbinput" == "SAVEON" ]
	then
		hold=1
		scanloops=1
		foreground=31
		status=5
		save_string="ON"
		statusline
		delay 2
	fi
	if [ "$kbinput" == "SAVEOFF" ]
	then
		hold=0
		coupling="AC"
		scanloops=1
		foreground=37
		status=1
		save_string="OFF"
		statusline
	fi
	# ***** Manual and Auto-saving facility end. ******
	#
	# ********* Load an existing binary file. *********
	if [ "$kbinput" == "LOAD" ]
	then
		status=0
		drawline=1
		hold=0
		coupling="AC"
		scanloops=1
		printf "\x1B[0m"
		clrscn
		# Ensure the last scan is saved for possible future use.
		savefile=$( date +%s )'.BIN'
		cp "$HOME"/AudioScope.tmp/waveform.raw "$HOME"/AudioScope.tmp/"$savefile"
		# Enter the required file for re-display.
		printf "%b" "BINARY CAPTURE FILE LISTING:-\n\n"
		ls -l "$HOME"/AudioScope.tmp/*.BIN
		printf "%b" "\nThe higher the numerical filename the newer the capture.\n\n"
		read -r -p "Enter the filename ONLY, not the path:- " -e kbinput
		kbinput="$HOME"'/AudioScope.tmp/'"$kbinput"
		echo ""
		echo "You entered $kbinput to view..."
		if [ "$kbinput" == $( ls "$kbinput" ) ]
		then
			echo ""
			echo "Copying file into storage area..."
			cp "$kbinput" "$HOME"/AudioScope.tmp/waveform.raw
			delay 4
		fi
		kbinput=""
		printf "%b" "\x1B[H\x1B[0;36;44m"
		clrscn
		display
		statusline
	fi
	# ******* Load an existing binary file end. *******
	#
	# ******* Low signal level, ZOOM, facility. *******
	if [ "$kbinput" == "ZOOM" ]
	then
		scanloops=1
		status=6
		hold=0
		coupling="AC"
		zoom
		statusline
		read -r -p "Press <CR> to continue:- " -n 1
		printf "%b" "\x1B[0;37;40m\x1B[20;14f                                                                 "
	fi
	# ***** Low signal level, ZOOM, facility end. *****
	#
	# *********** Horizontal shift control. ***********
	if [ "$kbinput" == "HSHIFT" ]
	then
		status=7
		scanloops=1
		hold=0
		coupling="AC"
		scan_start=0
		scan_jump=1
		timebase="Fastest possible"
		setup=" X=$timebase, Y=$vertical, $coupling coupled, $capturemode mode.$blankline"
		setup="${setup:0:76}"
		while true
		do
			printf "%b" "\x1B[0;37;40m\x1B[20;14f"
			# This input method is something akin to BASIC's INKEY$...
			read -r -p "Horizontal shift, press L, l, R, r, (Q or q to exit):- " -n 1 -s kbinput
			printf "%b" "\x1B[0;37;40m\x1B[20;14f                                                                 \x1B[0;37;40m\x1B[20;14f"
			if [ "$kbinput" == "Q" ] || [ "$kbinput" == "q" ]
			then
				break
			fi
			if [ "$kbinput" == "L" ] || [ "$kbinput" == "l" ] || [ "$kbinput" == "R" ] || [ "$kbinput" == "r" ]
			then
				if [ "$kbinput" == "r" ]
				then
					scan_start=$(( $scan_start + 64 ))
				fi
				if [ "$kbinput" == "R" ]
				then
					scan_start=$(( $scan_start + 1 ))
				fi
				if [ "$kbinput" == "l" ]
				then
					scan_start=$(( $scan_start - 64 ))
				fi
				if [ "$kbinput" == "L" ]
				then
					scan_start=$(( $scan_start - 1 ))
				fi
				if [ $scan_start -le 0 ]
				then
					scan_start=0
				fi
				if [ $scan_start -ge $scan_end ]
				then
					scan_start=$scan_end
				fi
				display
				statusline
				plot
				draw
			fi
		done
		statusline
		delay 1
	fi
	# ********* Horizontal shift control end. *********
	#
	# ** Symmetrical waveform frequency measurement. **
	if [ "$kbinput" == "FREQ" ]
	then
		status=8
		scanloops=1
		hold=0
		coupling="AC"
		freq_counter
		statusline
		delay 2
	fi
	# Symmetrical waveform frequency measurement end. *
	#
	# ********* Set to default AC input mode. *********
	if [ "$kbinput" == "AC" ]
	then
		status=1
		hold=0
		scanloops=1
		dc_flag=0
		freq=2000
		coupling="AC"
		statusline
	fi
	# ******* Set to default AC input mode end. *******
	#
	# ********* Detect DC polarity and level. *********
	if [ "$kbinput" == "DC" ]
	then
		status=1
		hold=1
		scanloops=1
		coupling="DC"
		if [ $dc_flag -eq 1 ]
		then
			arduino_dc
		fi
		if [ $dc_flag -eq 2 ]
		then
			alt_dc
		fi
		statusline
	fi
	# ******* Detect DC polarity and level end. *******
	#
	# ********** Arduino detection routine. ***********	
	if [ "$kbinput" == "ARDDET" ]
	then
		IFS=$'\n'
		status=1
		hold=1
		dc_flag=0
		scanloops=1
		coupling="AC"
		coupling_device="/dev/urandom"
		printf "\x1B[0m"
		clrscn
		while true
		do
			echo ""
			read -r -p "Remove Arduino if it is connected, then press <CR> to continue:- " -n 1
			delay 1
			first_listing=$( ls /dev )
			echo ""
			read -r -p "Now replace Arduino, then press <CR> to continue:- " -n 1
			delay 1
			second_listing=$( ls /dev )
			if [ ${#first_listing} -ge ${#second_listing} ]
			then
				printf "%b" "\n\x1B[1;31mArduino, (Diecimila), Board not found, switching back to AC coupling only... \x1B[0m"
				hold=0
				break
			fi
			coupling_device=$( comm -23 <(echo "$second_listing") <(echo "$first_listing") )
			# OSX 10.7.5 has two device entries, only the first one is needed.
			# $1 becomes the first device, $2 becomes the second device, etc...
			set -- $coupling_device
			coupling_device='/dev/'"$2"
			if [ "$2" != "ttyUSB0" ]
			then
				coupling_device='/dev/'"$1"
			fi
			# This line is for OSX 10.7+ and is dumped on an error.
			stty -f "$coupling_device" raw 9600 > /dev/null 2>&1
			# This line is for most Linux flavours and is also dumped on error.
			stty -F "$coupling_device" raw 9600 > /dev/null 2>&1
			if [ -e "$coupling_device" ]
			then
				printf "%b" "\n\x1B[1;32mArduino board, $coupling_device found, DC facility enabled... \x1B[0m"
				dc_flag=1
				hold=1
				# The below code is for the Arduino programming suite version 0015.
				# You will have to edit any very minor modifications to suit your version.
				# The Arduino used is the USB Diecimila Board and is only using one ADC...
				: > "$HOME"/AudioScope.tmp/Arduino_9600.pde
				chmod 755 "$HOME"/AudioScope.tmp/Arduino_9600.pde
				printf "%b" '/* PDE code for Arduino as a single channel ADC for AudioScope.sh... */\n' >> "$HOME"/AudioScope.tmp/Arduino_9600.pde
				printf "%b" 'int analogue0 = 0;\n' >> "$HOME"/AudioScope.tmp/Arduino_9600.pde
				printf "%b" 'void setup() {\n' >> "$HOME"/AudioScope.tmp/Arduino_9600.pde
				printf "%b" '        Serial.begin(9600);\n' >> "$HOME"/AudioScope.tmp/Arduino_9600.pde
				printf "%b" '        analogReference(DEFAULT);\n' >> "$HOME"/AudioScope.tmp/Arduino_9600.pde
				printf "%b" '}\n' >> "$HOME"/AudioScope.tmp/Arduino_9600.pde
				printf "%b" 'void loop() {\n' >> "$HOME"/AudioScope.tmp/Arduino_9600.pde
				printf "%b" '        analogue0 = analogRead(0);\n' >> "$HOME"/AudioScope.tmp/Arduino_9600.pde
				printf "%b" '        analogue0 = analogue0/4;\n' >> "$HOME"/AudioScope.tmp/Arduino_9600.pde
				printf "%b" '        Serial.print(analogue0, BYTE);\n' >> "$HOME"/AudioScope.tmp/Arduino_9600.pde
				printf "%b" '}\n' >> "$HOME"/AudioScope.tmp/Arduino_9600.pde
				# Arduino PDE code end.
			fi
			break
		done
		delay 2
		IFS="$ifs_str"
		clrscn
		display
		statusline
	fi
	# ******* End of Arduino detection routine. *******
	#
	# ******** Alternate home built DC device. ********
	# This board will only works in SOX mode.
	if [ "$kbinput" == "ALTDC" ] && [ "$capturemode" == "SOX" ] && [ "${u_name:0:6}" != "CYGWIN" ]
	then
		altdc="V"
		status=1
		hold=1
		dc_flag=0
		scanloops=1
		coupling="AC"
		coupling_device="/dev/urandom"
		printf "%b" "\x1B[0;37;40m\x1B[22;3f$blankline\x1B[22;4f"
		printf "%b" "\x1B[0;32;40m\x1B[22;4fSetting up the switching and converter boards...\x1B[0;37;40m\x1B[20;14f"
		read -r -p "Press C<CR> (CHOPPER), F<CR> (COUNTER) or V<CR> (VCO):- " -e altdc
		printf "%b" "\x1B[0;37;40m\x1B[20;14f                                                                 \x1B[20;14f"
		# Set up and initialise the board for the first real DC capture...
		freq_counter
		alt_dc
	fi
	# **** End of alternate home built DC device. *****
	#
	# ******* Play an 8 second sinewave burst. ********
	if [ "$kbinput" == "BURST" ]
	then
		scanloops=1
		# Look for OSX 10.7+ "afplay" first...
		afplay "$HOME"/AudioScope.tmp/sinewave.wav > /dev/null 2>&1
		# Then look for Linux "aplay"...
		aplay "$HOME"/AudioScope.tmp/sinewave.wav > /dev/null 2>&1
		# And finally for CYGWIN and/or DSP in /dev/dsp mode ONLY...
		if [ $demo -eq 1 ]
		then
			cat < "$HOME"/AudioScope.tmp/sinewave.raw > /dev/dsp
		fi
	fi
	# ********** 8 second sinewave burst end. *********
	#
	# ************** The sweep generator. *************
	if [ "$kbinput" == "SWEEP" ]
	then
		scanloops=1
		printf "%b" "\x1B[0;32;40m\x1B[22;3f$blankline\x1B[22;4fGenerating the sweep.wav and sweep.raw files, please wait a few seconds...\x1B[20;14f"
		number=0
		count=0
		char=" ~"
		str=""
		# Initialise all files to zero.
		: > "$HOME"/AudioScope.tmp/sweeper.raw
		: > "$HOME"/AudioScope.tmp/sweep.raw
		: > "$HOME"/AudioScope.tmp/sweep.wav
		# Generate the high start sound at 4KHz.
		for number in $( seq 0 1 5 )
		do
			printf "%b" "$char" >> "$HOME"/AudioScope.tmp/sweeper.raw
		done
		# Now build up the char by adding the correct byte values at the beginning first then the end last.
		for count in $( seq 0 46 )
		do
			# Add the correct byte at the beginning, append the file, looping a few times...
			char=' '$char
			for number in $( seq 0 1 3 )
			do
				printf "%b" "$char" >> "$HOME"/AudioScope.tmp/sweeper.raw
			done
			# Now add the correct byte at the end, append the file, looping a few times...
			char=$char'~'
			for number in $( seq 0 1 2 )
			do
				printf "%b" "$char" >> "$HOME"/AudioScope.tmp/sweeper.raw
			done
		done
		# Now to reverse the file sweeper.raw byte by byte using builtins and append to sweeper.raw.
		# This is a little slow but it works perfectly Note that it will be very slow in CygWin.
		str=$( cat < "$HOME"/AudioScope.tmp/sweeper.raw )
		count=$(( ${#str} - 1 ))
		while [ $count -ge 0 ]
		do
			printf "%b" "${str:$count:1}" >> "$HOME"/AudioScope.tmp/sweeper.raw
			count=$(( $count - 1 ))
		done
		# Create a few seconds of sweeper from 4KHz to about 85Hz and back again...
		cp "$HOME"/AudioScope.tmp/sweeper.raw "$HOME"/AudioScope.tmp/sweep.raw
		cat "$HOME"/AudioScope.tmp/sweeper.raw >> "$HOME"/AudioScope.tmp/sweep.raw
		# This is the required .WAV header...
		printf "%b" "\x52\x49\x46\x46\x6c\xfe\x00\x00\x57\x41\x56\x45\x66\x6d\x74\x20\x10\x00\x00\x00\x01\x00\x01\x00\x40\x1f\x00\x00\x40\x1f\x00\x00\x01\x00\x08\x00\x64\x61\x74\x61\x48\xfe\x00\x00" >> "$HOME"/AudioScope.tmp/sweep.wav
		cat "$HOME"/AudioScope.tmp/sweep.raw >> "$HOME"/AudioScope.tmp/sweep.wav
		printf "%b" "\x1B[0;33;40m\x1B[22;3f$blankline\x1B[22;4fAll done, now sweeping from 4KHz to about 85Hz and back...\x1B[20;14f"
		# Look for OSX 10.7+ "afplay" first...
		afplay "$HOME"/AudioScope.tmp/sweep.wav > /dev/null 2>&1
		# Then look for Linux "aplay"...
		aplay "$HOME"/AudioScope.tmp/sweep.wav > /dev/null 2>&1
		# And finally for CYGWIN and/or DSP in /dev/dsp mode ONLY...
		if [ $demo -eq 1 ]
		then
			cat < "$HOME"/AudioScope.tmp/sweep.raw > /dev/dsp
		fi
	fi
	# ************ End of sweep generator. ************
	#
	# ******** Determine the display polarity. ********
	if [ "$kbinput" == "POLARITY" ]
	then
		scanloops=1
		status=0
		printf "%b" "\x1B[0m"
		clrscn
		echo ""
		echo "1) The THIRD circuit, 'DC output control board', in 'DC restorer mode', IS"
		echo "   needed for this second part of the calibration."
		echo "2) An analogue multimeter IS also needed for this part of the calibration."
		echo "3) Connect the 'DC output control board' to the stereo earphone output."
		echo "4) Connect the DC multimeter probes to the output terminals, black to _GND_."
		read -r -p "5) Press <CR> and note, A, the FIRST voltage reading:- " -n 1
		# Use three playback methods for the polarity check.
		# Playback the pulse1.wav file first.
		afplay "$HOME"/AudioScope.tmp/pulse1.wav > /dev/null 2>&1
		aplay "$HOME"/AudioScope.tmp/pulse1.wav > /dev/null 2>&1
		if [ $demo -eq 1 ]
		then
			cat < "$HOME"/AudioScope.tmp/pulse1.wav > /dev/dsp
		fi
		echo "6) Do not disconnect anything yet..."
		read -r -p "7) Press <CR> and note, B, the SECOND voltage reading:- " -n 1
		# Now playback the pulse2.wav next.
		afplay "$HOME"/AudioScope.tmp/pulse2.wav > /dev/null 2>&1
		aplay "$HOME"/AudioScope.tmp/pulse2.wav > /dev/null 2>&1
		if [ $demo -eq 1 ]
		then
			cat < "$HOME"/AudioScope.tmp/pulse2.wav > /dev/dsp
		fi
		echo "8) The LOWEST voltage reading is the required one so..."
		read -r -p "9) Press A or B for the LOWEST voltage reading, then <CR> " -e char
		if [ "$char" == "A" ] || [ "$char" == "a" ]
		then
			mv "$HOME"/AudioScope.tmp/pulse1.wav "$HOME"/AudioScope.tmp/pulse.wav
		else
			mv "$HOME"/AudioScope.tmp/pulse2.wav "$HOME"/AudioScope.tmp/pulse.wav
		fi
		echo ""
		echo "10) The polarity variable will need setting to either 0 or 1 manually,"
		echo "    either inside this script in the variables section, OR, inside"
		echo "    the AudioScope.Config file to produce a positive going pulse..."
		echo ""
		echo "11) Setting the correct pulse waveform for calibration..."
		echo ""
		read -r -p "12) Consult the manual for the full setup proceedure. <CR> to exit:- " -n 1
		char=$( which afplay )
		if [ "$char" != "" ]
		then
			: > /tmp/polarity.sh
			chmod 755 /tmp/polarity.sh
			echo 'echo "Press Ctrl-C to Quit..."; while true; do afplay "$HOME"/AudioScope.tmp/pulse.wav; sleep 2; done' >> /tmp/polarity.sh
			NewCLI /tmp/polarity.sh & > /dev/null 2>&1
			delay 1
			rm /tmp/polarity.sh
		fi
		char=$( which aplay )
		if [ "$char" != "" ]
		then
			xterm -e 'echo "Press Ctrl-C to Quit..."; while true; do aplay "$HOME"/AudioScope.tmp/pulse.wav; sleep 2; done' & > /dev/null 2>&1
		fi
		if [ $demo -eq 1 ]
		then
			printf "%b" 'echo "Press Ctrl-C to Quit..."\n' >> "$HOME"/AudioScope.tmp/pulsetest.sh
			printf "%b" 'while true\n' >> "$HOME"/AudioScope.tmp/pulsetest.sh
			printf "%b" 'do\n' >> "$HOME"/AudioScope.tmp/pulsetest.sh
			printf "%b" '        cat < "$HOME"/AudioScope.tmp/pulse.wav > /dev/dsp\n' >> "$HOME"/AudioScope.tmp/pulsetest.sh
			printf "%b" '        sleep 2\n' >> "$HOME"/AudioScope.tmp/pulsetest.sh
			printf "%b" 'done\n' >> "$HOME"/AudioScope.tmp/pulsetest.sh
			xterm -e "$HOME"/AudioScope.tmp/pulsetest.sh & > /dev/null 2>&1
			mintty "$HOME"/AudioScope.tmp/pulsetest.sh & > /dev/null 2>&1
		fi
		clrscn
		display
		statusline
	fi
	# ****** Determine the display polarity end. ******
	#
	# *** Print the X an Y range in the status bar. ***
	if [ "$kbinput" == "MODE" ]
	then
		status=1
		scanloops=1
		setup=" X=$timebase, Y=$vertical, $coupling coupled, $capturemode mode.$blankline"
		setup="${setup:0:76}"
	fi
	# ********* Print the X and Y ranges end. *********
	#
	# ** Display the last status in the status bar. ***
	if [ "$kbinput" == "STATUS" ]
	then
		scanloops=1
		status=$laststatus
		statusline
		delay 3
	fi
	# ********** Display the last status end. *********
	#
	# ***** Start of a one second playback burst. *****
	# ********** This assumes SOX mode only! **********
	if [ "$kbinput" == "PLAYBACK" ] && [ "$capturemode" == "SOX" ] && [ "${u_name:0:6}" != "CYGWIN" ]
	then
		drawline=1
		status=0
		hold=0
		scanloops=1
		number=48000
		coupling="AC"
		printf "%b" "\x1B[0;32;40m\x1B[22;3f$blankline\x1B[22;4fPlaying back the one second capture...\x1B[0;37;40m\x1B[20;14f"
		if [ $demo -eq 1 ]
		then
			number=8000
		fi
		# This condition is not needed but added for any future changes.
		if [ $demo -eq 4 ]
		then
			number=44100
		fi
		$capturepath -q -b 8 -r $number -e unsigned-integer "$HOME"/AudioScope.tmp/waveform.raw -d > /dev/null 2>&1
		statusline
	fi
	# *********** One second playback end. ************
	#
	# **** High resolution capture, SOX mode only! ****
	# ********** USE THIS AT YOUR OWN RISK!!! *********
	if [ "$kbinput" == "HIRES" ] && [ "$capturemode" == "SOX" ] && [ "${u_name:0:6}" != "CYGWIN" ]
	then
		# Save the current capture in UNIX _epoch_ date numerical filename format.
		savefile=$( date +%s )'.BIN'
		cp "$HOME"/AudioScope.tmp/waveform.raw "$HOME"/AudioScope.tmp/"$savefile"
		# This is a hidden added extra only. It will create a raw 1 second unsigned 16 bit mono sample at 192000Hz sampling rate.
		# This ASSUMES that the sound system inside your device is capable of the above sampling rate. USE IT AT YOUR OWN RISK!
		$capturepath -q -V0 -d -t raw -r 192000 -b 16 -c 1 -e unsigned-integer -> "$HOME"/AudioScope.tmp/waveform.raw trim 0 00:01
		vert_array=$( hexdump -v -e '1/2 "%u "' "$HOME"/AudioScope.tmp/waveform.raw )
		# A playback of the captured signal to test it has worked...
		$capturepath -q -b 16 -r 192000 -e unsigned-integer "$HOME"/AudioScope.tmp/waveform.raw -d > /dev/null 2>&1
	fi
	# ********* High resolution capture end. **********
	#
	# ******* Start another shell and terminal. *******
	# ** This assumes 'xterm' exists on your system. **
	# ********** USE THIS AT YOUR OWN RISK!!! *********
	if [ "$kbinput" == "SHELL" ]
	then
		printf "%b" "\x1B[0;37;40m\x1B[22;3f$blankline\x1B[22;4f"
		printf "%b" "\x1B[0;33;40m\x1B[22;4fAttempt to load a separate shell...\x1B[0;37;40m\x1B[20;14f"
		delay 2
		status=1
		str=$( which mintty )
		char=$( which xterm )
		if [ "$str" != "" ]
		then
			mintty &
		fi
		if [ "$char" != "" ]
		then	
			xterm &
		fi
		if [ "$u_name" == "Darwin" ]
		then
			NewCLI &
		fi
		statusline
	fi
	# ***** Start another shell and terminal end. *****
	#
	# ***** List the files generated by the code. *****
	if [ "$kbinput" == "LIST" ]
	then
		status=0
		printf "%b" "\x1B[0m"
		clrscn
		echo "The files generated by this code..."
		echo "-----------------------------------"
		echo ""
		echo "Files generated in the "$HOME"/AudioScope.tmp/ directory:-"
		echo ""
		echo "0000000000.BIN		1KHz-Test.sh		Arduino_9600.pde"
		echo "Untitled.m4a		VERT_BAT.BAT		VERT_DSP.sh"
		echo "VERT_SOX.sh		dcdata.raw		pulse1.wav"
		echo "pulse2.wav		pulsetest.sh		sample.raw"
		echo "signed16bit.txt		sinewave.raw		sinewave.wav"
		echo "squarewave.raw		sweep.raw		sweep.wav"
		echo "sweeper.raw		symmetricalwave.raw	symmetricalwave.wav"
		echo "waveform.raw		waveform.wav"
		echo ""
		echo "Files and directory generated in your "$HOME"/ directory:-"
		echo ""
		echo "-rw-r--r--  1 amiga staff  xxxxx 10 May 15:52 AudioScope.Circuits"
		echo "-rw-r--r--  1 amiga staff    xxx 10 May 15:52 AudioScope.Config"
		echo "-rw-r--r--  1 amiga staff xxxxxx 10 May 15:52 AudioScope.Manual"
		echo "-rwxr-xr-x@ 1 amiga staff xxxxxx 10 May 15:51 AudioScope.sh"
		echo "drwxr-xr-x 28 amiga staff    xxx 10 May 15:51 AudioScope.tmp"
		echo "-rw-r--r--  1 amiga staff   xxxx 10 May 15:52 AudioScope_Quick_Start.Notes"
		echo ""
		read -r -p "Press <CR> to continue:- " -n 1
		clrscn
		echo "EXTRA files generated in your /tmp/ directory when SOX and SPECAN is used:-"
		echo ""
		echo "FFT_WAV.py		Spec_An.sh		symmetricalwave.raw"
		echo "bash_array		symmetricalwave.wav"
		echo ""
		read -r -p "Press <CR> to continue:- " -n 1
		printf "%b" "\x1B[H\x1B[0;36;44m"
		clrscn
		display
		statusline
	fi
	# *************** File listing end. ***************
	#
	# *** Rerun, (RESET), the AudioScope.sh script. ***
	if [ "$kbinput" == "RESET" ]
	then
		# Reset the terminal back to normal...
		reset
		# Delete AudioScope.Config and waveform .raw for a complete default restart.
		rm "$HOME"/AudioScope.Config
		rm "$HOME"/AudioScope.tmp/waveform.raw
		# Ensure the terminal is cleared and reset.
		reset
		# IMPORTANT!!! ENSURE, AudioScope.sh is inside your _home_ drawer.
		exec "$HOME"/AudioScope.sh "$@"
	fi
	# ************* RESET capability end. *************
	#
	# *********** Read the manuals in situ. ***********
	if [ "$kbinput" == "MANUAL" ]
	then
		char=$( which less )
		hold=0
		clrscn
		if [ "$char" != "" ]
		then
			less "$HOME"/AudioScope.Manual
		else
			more "$HOME"/AudioScope.Manual
		fi
	fi
	if [ "$kbinput" == "NOTES" ]
	then
		char=$( which less )
		hold=0
		clrscn
		if [ "$char" != "" ]
		then
			less "$HOME"/AudioScope_Quick_Start.Notes
		else
			more "$HOME"/AudioScope_Quick_Start.Notes
		fi
	fi
	# ********** Manual and notes read end. ***********
	#
	# ********** Spectrum Analyser Display. ***********
	# ********* USE THIS AT YOUR OWN RISK!!! **********
	if [ "$kbinput" == "SPECAN" ] && [ "$capturemode" == "SOX" ] && [ "${u_name:0:6}" != "CYGWIN" ]
	then
		hold=0
		number=0
		char=()
		count=0
		printf "%b" "\x1B[0;37;40m\x1B[20;14f"
		read -r -p "Do you want to use the external source? (Y/N):- " -n 1 -e kbinput
		printf "%b" "\x1B[0;37;40m\x1B[20;14f                                                                 \x1B[0;37;40m\x1B[20;14f"
		number=($( ls -l "$HOME"/AudioScope.tmp/waveform.raw ))
		number=${number[4]}
		cp "$HOME"/AudioScope.tmp/waveform.raw /tmp/symmetricalwave.raw
		if [ $number -eq 48000 ]
		then
			char=($( hexdump -v -e '1/1 "%02x "' "$HOME"/AudioScope.tmp/waveform.raw ))
			count=0
			while [ $count -le 47999 ]
			do
				printf "\\x${char[$count]}"
				count=$(( $count + 6 ))
			done > "$HOME"/AudioScope.tmp/symmetricalwave.raw
		fi
		if [ "$kbinput" == "Y" ] || [ "$kbinput" == "y" ]
		then
			freq_counter
		fi
		spec_an
		display
	fi
	# ******** Spectrum Analyser Display end. *********
	#
	# ****** Clear all buffers and the display. *******
	if [ "$kbinput" == "CLEARALL" ]
	then
		printf "%b" "\033c\033[0m\033[3J\033[2J\033[H"
		return 0
	fi
	# ************ End of buffer clearing. ************
	setup=" X=$timebase, Y=$vertical, $coupling coupled, $capturemode mode.$blankline"
	setup="${setup:0:76}"
	statusline
	return 0
}

# #########################################################
# Help clears the screen to the startup defaults and prints command line help...
commandhelp()
{
	status=2
	printf "%b" "\x1B[0m"
	clrscn
	echo "CURRENT COMMANDS AVAILABLE:-"
	echo "<CR> ................................................. Reruns the scan(s) again."
	echo "RUN<CR> ......................... Reruns the scan(s), always with real captures."
	echo "QUIT<CR> .................................................... Quits the program."
	echo "HELP<CR> ................................................ This help as required."
	echo "HOLD<CR> ........................................ Switch to pseudo-storage mode."
	echo "DEMO<CR> .......... Switch capture to default DEMO mode and 10 continuous scans."
	echo "DSP<CR> ...................... Switch capture to Linux /dev/dsp mode and 1 scan."
	echo "SOX<CR> ....... Switch capture to multi-platform SOund eXchange mode and 1 scan."
	echo "ONE<CR> ......................................... Sets the number of scans to 1."
	echo "TEN<CR> ........................................ Sets the number of scans to 10."
	echo "HUNDRED<CR> ............. Sets the number of scans to 100, (not very practical)."
	echo "VER<CR> .................. Displays the version number inside the status window."
	echo "TBVAR<CR> ............ Set up uncalibrated user timebase offset and jump points."
	echo "        SubCommands: ............................. Follow the on screen prompts."
	echo "FASTEST<CR>, SLOWEST<CR> ...... Set timebase to the fastest or slowest possible."
	echo "1mS<CR>, 2mS<CR>, 5mS<CR> ............... Set scanning rate to 1, 2, or 5mS/DIV."
	echo "10mS<CR>, 20mS<CR>, 50mS<CR> .......... Set scanning rate to 10, 20 or 50mS/DIV."
	echo "100mS<CR> ...................................... Set scanning rate to 100mS/DIV."
	echo "VSHIFT<CR> ........... Set the vertical position from -4 to +4 to the mid-point."
	echo "        SubCommands: ............ Press U or D then <CR> when value is obtained."
	echo "DRAW<CR> .......... Connect up each vertical plot to give a fully lined display."
	echo ""
	read -r -p "Press <CR> to continue:- " -n 1
	clrscn
	echo "CURRENT COMMANDS AVAILABLE:-"
	echo "TRIG<CR> ........... Sets the synchronisation methods for storage mode retraces."
	echo "        SubCommand: SYNCEQ<CR> .. Synchronise from a variable, fixed value only."
	echo "        SubCommand: SYNCGT<CR> ......... Synchronise from a positive going edge."
	echo "        SubCommand: SYNCLT<CR> ......... Synchronise from a negative going edge."
	echo "        SubCommand: EXT<CR> ............ SOX ONLY. Follow the on screen prompts."
	echo "SAVEON<CR> .................... Auto-saves EVERY scan with a numerical filename."
	echo "SAVEOFF<CR> .............................. Disables auto-save facility, default."
	echo "ZOOM<CR> ................................ Low signal level gain, ZOOM, facility."
	echo "        SubCommand: 0<CR> ................. Default lowest zoom/gain capability."
	echo "        SubCommand: 1<CR> ............................. X2 zoom/gain capability."
	echo "        SubCommand: 2<CR> ............................. X4 zoom/gain capability."
	echo "        SubCommand: 3<CR> ............................. X8 zoom/gain capability."
	echo "        SubCommand: 4<CR> ............................ X16 zoom/gain capability."
	echo "        SubCommand: <CR> ...... To exit zoom mode when waveform has been viewed."
	echo "HSHIFT<CR> ............ Shift the trace left or right at the highest scan speed."
	echo "        SubCommand: L ........................ Shift the trace left by one byte."
	echo "        SubCommand: l ... Shift the trace left by 64 bytes, (one complete scan)."
	echo "        SubCommand: R ....................... Shift the trace right by one byte."
	echo "        SubCommand: r .. Shift the trace right by 64 bytes, (one complete scan)."
	echo "        SubCommand: Q or q ........ Exit back to normal usage, (quit this mode)."
	echo "RESET<CR> ............................ Do a complete COLD restart of the script."
	echo ""
	read -r -p "Press <CR> to continue:- " -n 1
	clrscn
	echo "CURRENT COMMANDS AVAILABLE:-"
	echo "FREQ<CR> ..... Measure a symmetrical waveform's frequency, accuracy 0.1 percent."
	echo "MODE<CR> .. Display the X, Y, coupling and mode ranges inside the status window."
	echo "STATUS<CR> . Display the previous status for 3 seconds inside the status window."
	echo "LOAD<CR> ..................................... Load a binary file for reviewing."
	echo "        SubCommand: ............................... Follow the on screen prompt."
	echo "AC<CR> ............................ Set vertical input to default AC input mode."
	echo "DC<CR> ................... Attempt to measure DC polarity and level. UNFINISHED."
	echo "BURST<CR> ........... Play an 8 second sinewave.wav burst using afplay or aplay."
	echo "ARDDET<CR> ................... Detect an Arduino (Diecimila) Board if available."
	echo "        SubCommand: .............................. Follow the on screen prompts."
	echo "ALTDC<CR> ........... Alternate home built DC input device using the sound card."
	echo "        SubCommand: ................................................ UNFINISHED."
	echo "POLARITY<CR> .............. Generate pulse waveforms purely for amplifier tests."
	echo "        Subcommand: .............................. Follow the on screen prompts."
	echo "SWEEP<CR> ................................. Sweep generator for bandwidth tests."
	echo "SAVE<CR> ............................... Manually save the current scan to disk."
	echo "V<CR> ......... Set the vertical Volts per Division range, (10mV), 100mV to 10V."
	echo "        SubCommand: .............................. Follow the on screen prompts."
	echo ""
	read -r -p "Press <CR> to continue:- " -n 1
	clrscn
	echo "FURTHER COMMANDS YOU CAN USE ENTIRELY AT YOUR OWN RISK!!!"
	# Use experimental 'QTMAC', 'WISNOUND' and 'ALSA' captures ENTIRELY at your own risk!
	echo "....... QTMAC, WINSOUND and ALSA capture modes you use at your own risk! ......."
	echo "QTMAC<CR> .............. EXPERIMENTAL MAC, (MBP), QuickTime Player capture mode."
	echo "WINSOUND<CR> ........ Special Windows SoundRecorder.exe for CygWin capture mode."
	echo "ALSA<CR> .................... Special Linux command line, arecord, capture mode."
	echo ""
	echo "HIDDEN COMMANDS:-"
	echo "..... For these hidden commands see Appendix D) of the AudioScope.Manual! ......"
	echo "MANUAL<CR>, NOTES<CR> ..... Read the AudioScope Manual or the Quick Start Notes."
	echo "LIST<CR>, EXIT<CR>, CLEARALL<CR> ........... Useful optional commands if needed."
        echo ""
	echo "PLAYBACK<CR>, HIRES<CR>, SHELL<CR>, SPECAN<CR> ... USE THESE AT YOUR OWN RISK!!!"
	echo ""
	read -r -p "Press <CR> to continue:- " -n 1
	printf "%b" "\x1B[H\x1B[0;36;44m"
	clrscn
	display
	statusline
}

# #########################################################
# This is the active part of the pseudo-synchronisation section.
trigger()
{
	while true
	do
		printf "%b" "\x1B[0;37;40m\x1B[20;14f"
		# This input method is something akin to BASIC's INKEY$...
		read -r -p "Sync point:- U for up 1, D for down 1, <CR> to RETURN:- " -n 1 -s sync_input
		printf "%b" "\x1B[0;37;40m\x1B[20;14f                                                                 \x1B[0;37;40m\x1B[20;14f"
		if [ "$sync_input" == "" ]
		then
			break
		fi
		if [ "$sync_input" == "U" ]
		then
			sync_point=$(( $sync_point + 1 ))
		fi
		if [ "$sync_input" == "D" ]
		then
			sync_point=$(( $sync_point - 1 ))
		# Ensure the synchronisation point is NOT out of bounds.
		fi
		if [ $sync_point -ge 240 ]
		then
			sync_point=240
		fi
		if [ $sync_point -le 15 ]
		then
			sync_point=15
		fi
		printf "%b" "\x1B[23;3f Synchronisation point set to \x1B[0;32;40m$sync_point\x1B[0;37;40m...                                        "
	done
}

# #########################################################
# This is the software zooming facility.
# This does NOT alter any user values at all.
zoom()
{
	printf "%b" "\x1B[0;37;40m\x1B[20;14f"
	read -r -p "Set ZOOM gain, (4 = maximum sensitivity), 1, 2, 3 or 4<CR> " -e kbinput
	printf "%b" "\x1B[0;37;40m\x1B[20;14f                                                                 \x1B[0;37;40m\x1B[20;14f"
	zoom_facility="OFF"
	zoom="Lowest sensitivity zoom/gain, default condition..."
	# Written longhand for anyone to understand how it works.
	if [ "$kbinput" == "1" ] || [ "$kbinput" == "2" ] || [ "$kbinput" == "3" ] || [ "$kbinput" == "4" ]
	then
		zoom_facility="ON"
	fi
	display
	# Just these four ranges are needed for the zoom facility.
	if [ "$zoom_facility" == "ON" ]
	then
		subscript=$scan_start
		vert_array=""
		for horiz in {9..72}
		do
			if [ "${u_name:0:6}" != "CYGWIN" ]
			then
				vert=$( hexdump -n1 -s$subscript -v -e '1/1 "%u"' "$HOME"/AudioScope.tmp/waveform.raw )
			else
				# CYGWIN mode.
				vert=$( od -An -N1 -j$subscript -tu1 "$HOME"/AudioScope.tmp/waveform.raw )
			fi
			# This inverts the waveform so as to display it correctly on screen.
			if [ $polarity -eq 1 ]
			then
				vert=$(( 255 - $vert ))
			fi
			if [ $vert -le 0 ]
			then
				vert=0
			fi
			if [ $vert -ge 255 ]
			then
				vert=255
			fi
			if [ "$kbinput" == "1" ]
			then
				zoom="\x1B[22;4f2X zoom/gain state..."
				vert=$(( $vert - 64 ))
				vert=$(( ( $vert / 8 ) + 2 ))
			fi
			if [ "$kbinput" == "2" ]
			then
				zoom="\x1B[22;4f4X zoom/gain state..."
				vert=$(( $vert - 96 ))
				vert=$(( ( $vert / 4 ) + 2 ))
			fi
			if [ "$kbinput" == "3" ]
			then
				zoom="\x1B[22;4f8X zoom/gain state..."
				vert=$(( $vert - 112 ))
				vert=$(( ( $vert / 2 ) + 2 ))
			fi
			if [ "$kbinput" == "4" ]
			then
				zoom="\x1B[22;4f16X zoom/gain state..."
				vert=$(( ( $vert - 120 ) + 2 ))
			fi
			if [ $vert -le 2 ]
			then
				vert=2
			fi
			if [ $vert -ge 17 ]
			then
				vert=17
			fi
			subscript=$(( $subscript + $scan_jump ))
			vert_array="$vert_array$vert "
			printf "%b" "\x1B[1;37;44m\x1B["$vert";"$horiz"f*"
		done
	fi
	# Revert to the plot function for the default lowest resolution.
	if [ "$zoom_facility" == "OFF" ]
	then
		plot
	fi
	draw
}

# #########################################################
# Frequency counter from 50Hz to 3500Hz.
# This function is used to detect the DC polarity too.
# The sampling rate is the lowest at 8000Hz as that is all that is needed.
freq_counter()
{
	printf "%b" "\x1B[0;37;40m\x1B[22;3f$blankline\x1B[22;4fWorking, please wait...\x1B[20;14f"
	IFS=$'\n'" "
	freq=0
	: > "$HOME"/AudioScope.tmp/symmetricalwave.raw
	# This is a demo mode so that there is no need to access HW.
	# Set at 2000Hz so as to always default to AC input mode.
	if [ $demo -eq 0 ]
	then
		delay 1
		cp "$HOME"/AudioScope.tmp/squarewave.raw "$HOME"/AudioScope.tmp/symmetricalwave.raw
	fi
	# The next two are for real grabs, this one is for /dev/dsp users...
	if [ $demo -eq 1 ] || [ $demo -eq 4 ]
	then
		dd if=/dev/dsp of="$HOME"/AudioScope.tmp/symmetricalwave.raw bs=1 count=12000 > /dev/null 2>&1
		dd if="$HOME"/AudioScope.tmp/symmetricalwave.raw of="$HOME"/AudioScope.tmp/sample.raw skip=4000 bs=1 count=8000 > /dev/null 2>&1
		cp "$HOME"/AudioScope.tmp/sample.raw "$HOME"/AudioScope.tmp/symmetricalwave.raw
	fi
	# This one is for SOX users.
	if [ $demo -eq 2 ]
	then
		# The absolute address will be found when running the code, but, it WILL take a LONG time to find...
		$capturepath -q -V0 -d -t raw -r 8000 -b 8 -c 1 -e unsigned-integer -> "$HOME"/AudioScope.tmp/symmetricalwave.raw trim 0 00:01
	fi
	if [ $demo -eq 3 ]
	then
		# ************* OSX 10.7.x version. *************
		# Clear the default directory of ALL *.aifc files OSX 10.7.x!
		# rm "$HOME"/Movies/*.aifc > /dev/null 2>&1
		# Capture ths signal.
		# QuickTime_Player > /dev/null 2>&1
		# Use the default converter to convert to a WAVE file for further manipulation OSX 10.7.x.
		# afconvert -f 'WAVE' -c 1 -d UI8@8000 "$HOME/Movies/Audio Recording.aifc" "$HOME"/AudioScope.tmp/symmetricalwave.wav
		# *************** OSX 10.7.x end. ***************
		# ************ OSX 10.12.x version. *************
		# Delete "$HOME"/AudioScope.tmp/Untitled/m4a OSX 10.12.x
		rm "$HOME"/AudioScope.tmp/Untitled.m4a > /dev/null 2>&1
		# Capture the signal.
		QuickTime_Player > /dev/null 2>&1
		# Use the default converter to convert to a WAVE file for further manipulation OSX 10.12.x.
		afconvert -f 'WAVE' -c 1 -d UI8@8000 "$HOME"/AudioScope.tmp/Untitled.m4a "$HOME"/AudioScope.tmp/symmetricalwave.wav
		# *************** OSX 10.12.x end. **************
		# Convert to a RAW file format for displaying.
		dd if="$HOME"/AudioScope.tmp/symmetricalwave.wav of="$HOME"/AudioScope.tmp/symmetricalwave.raw skip=4096 bs=1 count=8000 > /dev/null 2>&1
	fi
	if [ $demo -eq 5 ]
	then
		# ALSA mode.
		arecord -d 1 -c 1 -f U8 -r 8000 -t raw "$HOME"/AudioScope.tmp/symmetricalwave.raw > /dev/null 2>&1
	fi
	if [ "${u_name:0:6}" != "CYGWIN" ]
	then
		# All modes except CYGWIN.
		freq_array=($( hexdump -v -e '1/1 "%u "' "$HOME"/AudioScope.tmp/symmetricalwave.raw ))
	else
		# CYGWIN mode.
		freq_array=($( od -An -tu1 -w8000 < "$HOME"/AudioScope.tmp/symmetricalwave.raw ))
	fi
	subscript=0
	while true
	do
		# Assume a square wave "mark to space" ratio of 1 to 1 is used,
		# then "wait" until a "space" is found.
		# (For those that don't know.)
		#
		#                  +------+      +---
		# Square wave:-    | Mark |Space |
		#               ---+      +------+
		#
		# This ensures that the loop cycles when NO input is
		# applied to the microphone socket.
		# Exit this loop when "mark" is found or subscript >= 8000...
		while [ ${freq_array[$subscript]} -ge 128 ]
		do
			subscript=$(( $subscript + 1 ))
			# Ensure as soon as subscript >= 8000 occurs it drops out of the loop.
			if [ $subscript -ge 8000 ]
			then
				break
			fi
		done
		# Ensure as soon as subscript >= 8000 occurs it drops completely out of this loop.
		if [ $subscript -ge 8000 ]
		then
			break
		fi
		# Now the "mark" can loop until a "space" is found again and the whole
		# can cycle until subscript >= 8000...
		while [ ${freq_array[$subscript]} -le 127 ]
		do
			subscript=$(( $subscript + 1 ))
			# Ensure as soon as subscript >= 8000 occurs it drops out of the loop.
			if [ $subscript -ge 8000 ]
			then
				break
			fi
		done
		# Ensure as soon as subscript >= 8000 occurs it drops completely out of this loop.
		if [ $subscript -ge 8000 ]
		then
			break
		fi
		# "freq" will become the frequency of a symmetrical waveform
		# when the above loops are finally exited, subscript >= 8000...
		# Tick up the freq(uency) per "mark to space" cycle.
		freq=$(( $freq + 1 ))
	done
	IFS="$ifs_str"
}

# #########################################################
# Getting the DC and LF information using an Arduino Diecimila Board
arduino_dc()
{
	dc_str="0.000"
	for count in {1..2}
	do
		dd if="$coupling_device" of="$HOME"/AudioScope.tmp/dcdata.raw bs=1 count=1 > /dev/null 2>&1
		if [ "${u_name:0:6}" != "CYGWIN" ]
		then
			dc_data=$( hexdump -n1 -s0 -v -e '1/1 "%u"' "$HOME"/AudioScope.tmp/dcdata.raw )
		else
			# CYGWIN mode.
			dc_data=$( od -An -N1 -j0 -tu1 "$HOME"/AudioScope.tmp/dcdata.raw )
		fi
		if [ ${#dc_data} -le 0 ]
		then
			printf "%b" "\x1B[1;31mCRITICAL ERROR! Unsuccessful data aquisition... \x1B[0m"
			coupling="AC"
			coupling_device="/dev/urandom"
			dc_flag=0
			break
		fi
		dc_data=$(( $dc_data * 20 ))
		if [ ${#dc_data} -eq 2 ]
		then
			dc_str='0.0'"$dc_data"
		fi
		if [ ${#dc_data} -eq 3 ]
		then
			dc_str='0.'"$dc_data"
		fi
		if [ ${#dc_data} -eq 4 ]
		then
			dc_data="${dc_data:0:1}.${dc_data:1:2}"
			dc_str="$dc_data"'0'
		fi
	done
}

# #########################################################
# The control and capture of a DC component of a signal.
alt_dc()
{
	# Chopper version.
	dc_str="0.000"
	if [ "$altdc" == "C" ]
	then
		dc_flag=2
		coupling="AC"
		:
	fi
	# Frequency counter version.
	if [ "$altdc" == "F" ]
	then
		dc_flag=2
		coupling="AC"
		:
	fi
	# VCO version from 0, zero, to 2, two, volts DC.
	if [ "$altdc" == "V" ]
	then
		# Take a scan.
		waveform
		# Switch the input to DC mode, this switches relay on.
		trigger_pulse
		# Call the frequency counter to get the VCO frequency, "$freq".
		freq_counter
		wait
		number=0
		dc_flag=2
		coupling="DC"
		# Author's real calibrated values as an array, rounded up or down to the nearest 0 or 5.
		freq_array=( 0 860 945 1025 1110 1190 1275 1355 1445 1520 1605 1685 1770 1855 1940 2025 2110 2200 10000 )
		# Printed values referring to real frequency array values.
		dc_data=( 0.000 0.000 0.125 0.250 0.375 0.500 0.625 0.750 0.875 1.000 1.125 1.250 1.375 1.500 1.625 1.750 1.875 2.000 0.000 )
		while [ $number -lt ${#freq_array[@]} ]
		do
			if [ $freq -lt ${freq_array[$number]} ]
			then
				break
			fi
			number=$(( $number + 1 ))
		done
		if [ $number -gt 0 ] && [ $number -lt ${#freq_array[@]} ]
		then
			dc_str="${dc_data[$number]}"
		fi
	fi
}

# #########################################################
# Generate a DC output as a control pulse approximately 170mS wide.
# This uses the squarewave.raw file and the voltage doubler/filter as the
# trigger pulse generator.
# When the DC Control board coupled to the Timer board the DC capture mode is possible.
trigger_pulse()
{
	$capturepath -q -V0 -b8 -r48000 -e unsigned-integer "$HOME"/AudioScope.tmp/squarewave.raw -d
}

# #########################################################
# DC - 4KHz range AF spectrum analyser.
spec_an()
{
#!/bin/bash
# AF_Spec_An.sh
# $VER AF_Spec_An.sh_(C)2017_2020_B.Walker_CC0_Licence.
# Create the main shell script as a stand alone program.
: > /tmp/Spec_An.sh
chmod 755 /tmp/Spec_An.sh

# Create the shell script.
cat << "SPEC_AN" > /tmp/Spec_An.sh
#!/bin/bash
# Spec_An.sh
# GNU bash, version 3.2.57(1)-release (x86_64-apple-darwin16)
# Copyright (C) 2007 Free Software Foundation, Inc.
# $VER Spec_An.sh_(C)2017_2020_B.Walker_CC0_Licence.
# Create the blank files.
: > /tmp/symmetricalwave.wav
: > /tmp/bash_array
: > /tmp/FFT_WAV.py

# Current variables.
BASH_ARRAY=()
COUNT=0
HORIZ=11
VERT=${BASH_ARRAY[$COUNT]}
DRAW=0

# Create the symmetricalwave.wav file to view from AudioScope.sh.
# It MUST be a 1 second burst, mono, 8 bit, unsigned integer, 8KHz sample rate, recording.
printf "\x52\x49\x46\x46\x64\x1F\x00\x00\x57\x41\x56\x45\x66\x6D\x74\x20\x10\x00\x00\x00\x01\x00\x01\x00\x40\x1F\x00\x00\x40\x1F\x00\x00\x01\x00\x08\x00\x64\x61\x74\x61\x40\x1F\x00\x00" >> /tmp/symmetricalwave.wav
cat "$HOME"/AudioScope.tmp/symmetricalwave.raw >> /tmp/symmetricalwave.wav

# Create the display, active area x = 64, y = 21. Bold cyan on black with yellow plots.
printf "%b" "\x1B[1;36;40m\x1B[2J\x1B[H"
printf "%b" "\
         ++----[ \$VER Spec_An.sh_(C)2017_2020_B.Walker_CC0_Licence. ]-----++
     100 +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 100
         ||       |       |       |       |       |       |       |       ||
      90 ++       +       +       +       +       +       +       +       ++ 90
   R     ||       |       |       |       |       |       |       |       ||
   E  80 ++       +       +       +       +       +       +       +       ++ 80
   L     ||       |       |       |       |       |       |       |       ||
   A  70 ++       +       +       +       +       +       +       +       ++ 70
   T     ||       |       |       |       |       |       |       |       ||
   I  60 ++       +       +       +       +       +       +       +       ++ 60
   V     ||       |       |       |       |       |       |       |       ||
   E  50 ++       +       +       +       +       +       +       +       ++ 50
         ||       |       |       |       |       |       |       |       ||
   L  40 ++       +       +       +       +       +       +       +       ++ 40
   E     ||       |       |       |       |       |       |       |       ||
   V  30 ++       +       +       +       +       +       +       +       ++ 30
   E     ||       |       |       |       |       |       |       |       ||
   L  20 ++       +       +       +       +       +       +       +       ++ 20
Log10(X) ||       |       |       |       |       |       |       |       ||
      10 ++       +       +       +       +       +       +       +       ++ 10
         ||       |       |       |       |       |       |       |       ||
       0 ++-------+-------+-------+-------+-------+-------+-------+-------++ 0
 FREQ Hz +0------500----1000----1500----2000----2500----3000----3500----4000
                          \x1B[1;37;40mPress <CR> to continue:- "

# Create the Python code to do the heavy FFT lifting.
# DEPENDENCIES REQUIRED: scipy and scipy.io... 
cat << "PYTHON_CODE" > /tmp/FFT_WAV.py
# Python 2.7.10 (default, Feb  6 2017, 23:53:20) 
# [GCC 4.2.1 Compatible Apple LLVM 8.0.0 (clang-800.0.34)] on darwin
# Type "help", "copyright", "credits" or "license" for more information.
#
# $VER FFT_WAV.py_Text_Mode_AF_Spectrum_Display_(C)2017_2020_B.Walker_CC0_Licence.

import sys
import scipy
from scipy.io import wavfile

global ARRAY_STRING
ARRAY_STRING = ""

# Obtain the waveform from AudioScope.sh.
RATE, WAVEDATA = wavfile.read('/tmp/symmetricalwave.wav')
DATA = WAVEDATA.T
ELEMENTS = [(ELEMENT/2**8.0)*2-1 for ELEMENT in DATA]
COMPLEX = scipy.fft(ELEMENTS)

LIST = scipy.ndarray.tolist(abs(COMPLEX))

for SUBSCRIPT in range(7999, 3999, -1):
	FFT = int(LIST[SUBSCRIPT])
	# Force any Log10(0) to Log10(1).
	if FFT < 1.0: FFT = 1
	FFT = int(5*scipy.log10(FFT))
	ARRAY_STRING = ARRAY_STRING + str(FFT) + " "
filename = open('/tmp/bash_array', 'w+')
filename.write(ARRAY_STRING)
filename.close()
sys.exit()
PYTHON_CODE

# Now run the Python code.
python /tmp/FFT_WAV.py

# Place the python generated space delimited file into a bash array.
BASH_ARRAY=($( cat /tmp/bash_array ))

# Finally plot the audio spectrum.
COUNT=0
HORIZ=11
VERT=${BASH_ARRAY[$COUNT]}
DRAW=22
# Display window...
# HORIZ, 11 minimum, 75 maximum.
# VERT, 2 minimum, 22 maximum.
# VERT MUST be inverted.
while [ $COUNT -le 3999 ]
do
	VERT=$(( 22 - $VERT ))
	if [ $VERT -lt 2 ]
	then
		$VERT=2
	fi
	if [ $VERT -gt 22 ]
	then
		VERT=22
	fi
	if [ $HORIZ -gt 75 ]
	then
		# This should never be reached with AudioScope's WAV file. 
		break
	fi
	for (( DRAW=22; DRAW>=$VERT; DRAW-- ))
	do
		printf "%b" "\x1B[${DRAW};${HORIZ}f\x1B[1;33;40m*"
	done
	if [ $(( $COUNT % 63 )) -eq 0 ]
	then
		HORIZ=$(( $HORIZ + 1 ))
	fi
	COUNT=$(( $COUNT + 1 ))
	VERT=${BASH_ARRAY[$COUNT]}
done
printf "\x1B[24;52f"
read -r -n 1
exit 0
SPEC_AN

# Call the newly created Spec_An.sh file...
/tmp/Spec_An.sh
}

# #########################################################
# Set up an initial screen ready to enter the main loop...
display
statusline
if [ $demo -eq 3 ]
then
	Enable_QT
	wait
	delay 1
fi

# #########################################################
# This is the main loop...
while true
do
	for scan in $( seq 1 $scanloops )
	do
		# "hold" determines a new captured scan or retrace of an existing scan...
		if [ $hold -eq 1 ]
		then
			waveform
		fi
		if [ "$coupling" == "DC" ]
		then
			printf "%b" "\x1B[0;37;40m\x1B[22;3f$blankline\x1B[22;4f"
			printf "%b" "\x1B[0;32;40m\x1B[22;4fFor ARDUINO and DEMO DC mode only...\x1B[0m\x1B[20;14f"
			if [ $dc_flag -eq 0 ]
			then
				coupling_device="/dev/urandom"
				dc_flag=1
			fi
			if [ $dc_flag -eq 1 ]
			then
				arduino_dc
				delay 1
			fi
		fi
		if [ "$coupling" == "DC" ] &&[ "$capturemode" == "SOX" ] && [ "${u_name:0:6}" != "CYGWIN" ]
		then 
			printf "%b" "\x1B[0;37;40m\x1B[22;3f$blankline\x1B[22;4f"
			printf "%b" "\x1B[0;31;40m\x1B[22;4fFor alternate DC board, SOX mode only...\x1B[0m\x1B[20;14f"
			if [ $dc_flag -eq 2 ]
			then
				alt_dc
			fi
		fi
		display
		statusline
		plot
		if [ $drawline -eq 1 ]
		then
			draw
		fi
		if [ "$save_string" == "ON" ]
		then
			savefile=$( date +%s )'.BIN'
			cp "$HOME"/AudioScope.tmp/waveform.raw "$HOME"/AudioScope.tmp/"$savefile"
		fi
	done
	setup=" X=$timebase, Y=$vertical, $coupling coupled, $capturemode mode.$blankline"
	setup="${setup:0:76}"
	laststatus=$status
	status=0
	scanloops=1
	scan=1
	if [ $hold -eq 1 ]
	then
		printf "%b" "\x1B[1;37f\x1B[1;31;44mCAPTURE\x1B[0;36;44m"
	else
		printf "%b" "\x1B[1;37f\x1B[1;32;44mSTORAGE\x1B[0;36;44m"
	fi
	if [ "$coupling" == "AC" ]
	then
		dc_str="      OFF      "
	fi
	printf "%b" "\x1B[18;33f\x1B[1;36;44m      Volts +DC\x1B[18;33f$dc_str\x1B[0;37;40m"
	printf "%b" "\x1B[24;37f\x1B[1;32;40m     Hz\x1B[24;37f$freq\x1B[0;37;40m\x1B[20;14f"
	if [ ! -f "$HOME"/AudioScope.Config ]
	then
		delay 1
		for number in {1..18}
		do
			printf "%b" "\x1B[1;37;44m\x1B[$number;3f$blankline\x1B[H"
		done
		echo ""
		echo "                 THE VERY FIRST RUN OR USE OF THE RESET COMMAND."
		echo "                 -----------------------------------------------"
		echo ""
		echo "   If you see this screen then it is either a very first time run or you have"
		echo "   entered the RESET<CR> command to do a complete cold start of this program."
		echo ""
		echo "   Inside the COMMAND window enter the  command QUIT<CR> to immediately quit."
		echo ""
		echo "   This will create all the remaining  files needed for a minimum of the DEMO"
		echo "   default learning mode.  Once you are back into the terminal just rerun the"
		echo "   program again and  you will be in full running DEMO learning mode.  Enjoy!"
		echo ""
		echo "   You will then have  access to  the full Manual, the MANUAL<CR> command and"
		echo "   the Quick Start Notes,  the NOTES<CR> command to view at any time.  If you"
		echo "   just want to play without building any hardware  then read the Quick Start"
		echo "   Notes, the NOTES<CR> command. Have hours of fun!"
		echo "                                 Barry, G0LCU." 
	fi
	freq="  OFF  "
	statusline
	kbcommands
	if [ $? -eq 10 ]
	then
		status=255
		break
	fi
done

# #########################################################
# Getout, autosave AudioScope.Config, cleanup and quit...
if [ $status -eq 255 ]
then
	setup=" X=$timebase, Y=Uncalibrated (m)V/DIV, $coupling coupled, $capturemode mode.$blankline"
	setup="${setup:0:76}"
	# Save the user configuration file.
	user_config
	# Reset the terminal size to original.
	vert=${term_size[0]}
	horiz=${term_size[1]}
	printf "%b" "\x1B[8;"$vert";"$horiz"t"
	# Remove "Shell AudioScope" from the title bar.
	printf "%b" "\x1B]0;\x07"
	# Do a complete terminal reset.
	reset
	IFS="$ifs_str"
fi
printf "%b" "\nProgram terminated...\n\nTerminal reset back to startup defaults...\n"
printf "%b" "\nSaving the manual, quick start notes AND text mode circuit diagrams as:-\n\n""$HOME/AudioScope.Manual...\n"
printf "%b" "\nSaving a quick start manual as:-\n\n""$HOME/AudioScope_Quick_Start.Notes...\n"
printf "%b" "\nSaving dedicated text mode circuit diagrams as:-\n\n""$HOME/AudioScope.Circuits...\n\n"
: > "$HOME"/AudioScope.Manual
cat << "MANUAL" > "$HOME"/AudioScope.Manual
#
# AudioScope.Manual.
# ------------------
#
# Preface:-
# ---------
#
# Public Domain, 2013-2020, B.Walker, G0LCU.
# Issued under the Creative Commons, CC0, licence.
#
# If you have any comments good or bad with what you see please send an 
# email to:-
# wisecracker.bazza@gmail.com
# Thank you in advance...
#
# This fun project started life in January 2013 on a MacBook Pro, OSX 10.7.3
# and continues to be developed on the current OSX version of the day WRT the
# file date and time stamps.
#
# IMPORTANT!!! This code assumes that it is saved as AudioScope.sh inside your
# _home_ drawer...
# Set the permissions to YOUR requirements and launch the code using the
# following:-
#
# Your Prompt> ./AudioScope.sh<CR>
#
# VERY IMPORTANT!!! Some Linux/*NIX installs might require that you run this
# code in root mode inside a terminal for ALL possible available facilities.
# Arduino access is one possible event.
# Be very, VERY aware of this!!! If you do run a terminal in root mode, you do
# so at your own risk.
# Also there might be some dependencies beyond my control too, e.g. 'xterm' is
# not part of a default install on Linux Mint 17, so therefore be aware of any
# of these anomalies too. It is now hidden in OSX 10.11.x and above but is now
# recoded for OSX 10.12.x's terminal.
# Linux users will still have to fend for themselves. ;o)
# This is being developed primarily on a MacBook Pro 13 inch, OSX 10.12.x
# minimum; bash version... GNU bash, version 3.2.57(1)-release
# (x86_64-apple-darwin16), Copyright (C) 2007 Free Software Foundation, Inc.
# Also tested on PCLinuxOS 2009 and Debian 6.0.x, 32 bit, for backwards
# compatibility.
# CygWin and CygWin64 are also catered for but some operations WILL be very,
# very slow.
# Now testing includes Linux Mint 17, 64 bit as a Linux OS.
# All references to Debian 6.0.x cease as of AudioScope.sh Version 0.30.40.
# All references to PCLinuxOS 2009 also cease as of version 0.31.20.
# An iMAC, OSX 10.12.x, Sierra. OSX 10.7.x to 10.11.x are no longer catered
# for.
# The current Quicktime Player capture now does NOT work BELOW El Capitan,
# but SOX does. It does NOW work on OSX 10.12.x, Sierra. It takes a few seconds
# for a single capture, but HEY, it works on a virgin OSX 10.12.x, Sierra
# install and requires no dependences.
# Windows "SoundRecorder.exe" no longer exists in Windows 10, (it is now called
# "Voice Recorder"), so this capture mode is now broken as of 29th July, 2016.
# Therefore "/dev/dsp" is the only capture mode for CygWin and CygWin64. SOX is
# not catered for in CygWin. If you want to capture via any other method in
# CygWin(64) you will have to experiment for yourselves.
#
# Now tested on a Windows 8.1 AND a Windows 10 machine running CygWin(64) using
# the default CygWin(64) /dev/dsp mode. Note: The Windows batch file and SOX is
# needed for the sinewave calibration tests.
# Tested on all four in DEMO mode.
# Now tested with 3 more capture formats, Windows SoundRecorder.exe, Linux
# ALSA arecord and QuickTime Player, for CygWin, Linux ALSA and finally Apple
# OSX specific modes.
#
# This incomplete AudioScope.Manual with circuits at the end of this script is
# autosaved on program exit.
#
# Linux Format review, April 2014, LXF 182, page 65...
#
# At this point I will include and say thank you to "Corona688", a member of
# https://www.unix.com for his input.
# Also to "Don Cragun" and others on the same site for their input too.
# Also to "MadeInGermany" on the same site who helped with a problem found with
# the 'find' command when detecting 'SOX'.
# Also to "xbin" who showed me the way to create a second terminal in
# OSX 10.12.x instead of my method.
# Many thanks also go to the guys who have helped with this on
# https://www.linuxformat.com for all your input too.
# Also to an anonymous person, nicknamed Zoonie, who has given this project
# some serious hammering in the past...
# Finally, thanks to my wife for putting up with my coding experiments... ;o)
#
# Official releases will ALWAYS be at these two sites below:-
# https://www.unix.com/shell-programming-and-scripting/212939-start-simple-audio-scope-shell-script.html
# Which now follows on here:-
# https://www.unix.com/os-x-apple-/269769-audioscope-project.html
# Also there may be unofficial releases on these two sites/forums too.
#
# Due to issues I had with github this URL is no longer being updated for the
# time being!
# httpss://github.com/wisecracker-bazza/Scope
# Many photos can be found here however...
# Enjoy...
#
# (Apologies for any missed typos and errors.)
#
# Quick start:-
# -------------
#
# First time run of AudioScope.sh:-
# ---------------------------------
#
# Development tool:- Macbook Pro 13 inch, OSX 10.12.4, Sierra; bash version...
# GNU bash, version 3.2.57(1)-release (x86_64-apple-darwin16),
# Copyright (C) 2007 Free Software Foundation, Inc.
# Using the default Black on White, 80 x 24 Terminal.
#
# I will assume at this point that this manual will only be read as a weapon
# of last resort. So this part will be the important part as we all want to
# try out our new toy as soon as possible... ;o)
#
# <CR> == Carriage Return Key.
#
# The very first check is the terminal window size. An EXACT value of 80
# columns by 24 lines IS required so an attempt to force it to this size using
# the terminal escape code '\x1B[8;24;80t' is used. This is because there are
# now Linux installs where sizes are non standard, 60 x 16 and 77 x 23 are but
# two. One wonders why, but there you go.
# If this does NOT work on your terminal of choice then you WILL have to resize
# the terminal window manually yourself to an EXACT value of 80 x 24 to get
# this fun project to work correctly.
# If this is NOT possible with your terminal then the program WILL abort with
# the ERROR report to fit the 60 x 16 terminal size:-
#
# Your Prompt> ./AudioScope.sh<CR>
#
# A terminal window size of 80 columns x 24 lines IS required
# for this program to work!
#
# This terminal will not auto-resize using the escape codes.
#
# You will have to manually resize the terminal to EXACTLY
# 80 columns x 24 lines and restart AudioScope.sh again.
#
# Aborting program...
#
# Your Prompt> _
#
# (NOTE:- On program closedown the terminals that can be resized are returned
# back to the default values and are reset back to their default states.)
#
# NOW THE PROGRAM PROPER!
#
# ON FIRST TIME RUN, TYPE QUIT<CR> INSIDE THE BLACK COMMAND WINDOW TO QUIT THE
# PROGRAM IMMEDIATELY. RESTART THE PROGRAM AND _ALL_ FILES WILL HAVE BEEN
# GENERATED.
#
# Ensure that AudioScope.sh is in your $HOME drawer\directory\folder and once
# there change the access rights to rwxr-xr-x, (755).
# Launch the program from the command prompt as ./AudioScope.sh<CR>
# On program startup the terminal window is cleared and a notification is
# displayed along with a progress bar like this:-
#
#
#                                 IMPORTANT!!!
#                                 ------------
#
#            TERMINAL ESCAPE CODES  ARE USED EXTENSIVELY THROUGHOUT
#            THE PROGRAM RUN.  PICK A TERMINAL FOR THIS CAPABILITY.
#
#
#            Please wait while everything required is being set up.
#            For CygWin users this might take quite a long time....
#
#            Progress ............................ DONE!
#
#
# Once 'DONE!' is reached then most/any files required for your setup will be
# created.
#
# The Title Bar of the terminal window is then changed to include the program
# being run and its current version. It checks for a configuration file and if
# none exists then the defaults are used. The terminal window is cleared again
# and the AudioScope.sh will display a full scan for about one second then
# switch to the screen below, generated in FULL colour...
#
#
#                THE VERY FIRST RUN OR USE OF THE RESET COMMAND.
#                -----------------------------------------------
#
#  If you see this screen then it is either a very first time run or you have
#  entered the RESET<CR> command to do a complete cold start of this program.
#
#  Inside the COMMAND window  enter the command QUIT<CR> to immediately quit.
#
#  This will create ALL the remaining  files needed for a minimum of the DEMO
#  default learning mode.  Once you are back into the terminal just rerun the
#  program again and  you will be in full running DEMO learning mode.  Enjoy!
#
#  You will then have  access to  the full Manual, the MANUAL<CR> command and
#  the Quick Start Notes,  the NOTES<CR> command to view at any time.  If you
#  just want to play without building any hardware  then read the Quick Start
#  Notes, the NOTES<CR> command. Have hours of fun!
#                                Barry, G0LCU.
#+-----------------------------[COMMAND  WINDOW]------------------------------+
#| COMMAND:- Press <CR> to (re)run, HELP or QUIT<CR>:- _                      |
#+------------------------------[STATUS WINDOW]-------------------------------+
#| Stopped...                                                                 |
#| $VER: AudioScope.sh_Version_?.??.??_2013-2020_Public_Domain_B.Walker_G0LCU.|
#+---------------------------------[  OFF  ]----------------------------------+
#
#
# Enter QUIT<CR> in the COMMAND window and ALL the files needed for a full,
# minimal, initial DEMO learning mode will be created. Restart the program and
# it will go almost immediately to the scan screen as shown below.
#
# The 'CAPTURE', coloured red, momentarily shows as 'DISPLAY', coloured white
# during the capturing process. Both of the 'OFF' bracketed windows will also
# momentarily display 'DC VOLTS' and 'COUNTER' in White and then change to
# their respective colours of Cyan and Green, this is not a bug but a builtin.
#
#
#      +-------+-------+-------+---[CAPTURE]---+-------+-------+--------+
#      |       |       |       |       +       |     * |     * |  *     | MAX
#      |       |       |  *    |       +       |       |       |        |
#      |    *  |       *       |*      +       |       |       |        |
#    + +-**----+-------+---**--+-------+---*---+-------+-*-----+--------+
#      |   *   |       |       |       +  *    |*      |       |    * * |
#      |     * |       | *   * |     * +       |  *    |      *|       *|
#      |*      |       |       |       +       |       |       * *      |
#    0 +-+-+-+-+-+-+-+-+-+-+-+-*-+-+-+-+-+-+*+*+-+-+-+-+*+-+-+-+-+-+-+--+ REF
#      |       |*     *|       |       +       |       |       |   *    |
#      |       | **    |      *|       +       *   *   |       |        |
#      |       |     * |       |  *    +       | *     |   *   |        |
#    - +-------+-------+-------+----*--+-------+------*+--*----+--------+
#      |       *       |*      |       +**     |    *  |       |*       |
#      |       |       |       |       +       |       |       |     *  |
#      |       |    *  |       | * *  **     * |       *       |        |
#      |      *|   *   |       |       +       |       |    *  |        | MIN
#      +-------+-------+-------[      OFF      ]-------+-------+--------+
#+-----------------------------[COMMAND  WINDOW]------------------------------+
#| COMMAND:- Press <CR> to (re)run, HELP or QUIT<CR> _                        |
#+------------------------------[STATUS WINDOW]-------------------------------+
#| Stopped...                                                                 |
#| X=Uncalibrated (m)S/DIV, Y=Uncalibrated (m)V/DIV, AC coupled, DEMO mode.   |
#+---------------------------------[  OFF  ]----------------------------------+
#
#
# This is the normal DEMO default state, where ?.??.?? is the current version.
#
# The first run startup defaults:-
# --------------------------------
# 1) DEMO mode for all *NIX like platforms.
# 2) Plotted points only.
# 3) Capture source:- /dev/urandom.
# 4) Single sweep.
# 5) Auto-save OFF.
# 6) TRIGGER/SYNC OFF.
# 7) Stopped state.
# 8) COMMAND line mode.
# 9) The three very basic commands that are required for very basic use.
# 10) Uncalibrated AC coupled vertical sensitivity.
# 11) Fastest _uncalibrated_ timebase speed.
# 12) Internal microphone only.
#
# The only _DEPENDENCY_ for FULL AC(/DC) capture is Sound eXchange; SOX.
# It can be found here:- https://sox.sourceforge.net
# The minimum SOX version required is 14.4.0...
# Other capture modes ARE available but they are machine specific.
#
# The DC sections are purely optional if only AC is required so these can be
# ignored. This includes the Arduino Diecimila board for DC access too.
# If the Arduino Diecimila board is needed then the USB driver(s) will be
# required, see the details later in this manual.
# AC mode is now completed as of Version 0.50.00.
#
# Enjoy the first run, now read on...
#
# The builtin HELP:-
# ------------------
# These commands will be expanded upon later, type HELP<CR> to show these
# commands. Note that the commands are nearly all UPPER CASE ONLY. They are
# paged so just press <CR> to see the next page. So far there are four pages.
#
# <CR> .............................................. Reruns the scan(s) again.
# RUN<CR> ...................... Reruns the scan(s), always with real captures.
# QUIT<CR> ................................................. Quits the program.
# HELP<CR> ............................................. This help as required.
# HOLD<CR> ..................................... Switch to pseudo-storage mode.
# DEMO<CR> ....... Switch capture to default DEMO mode and 10 continuous scans.
# DSP<CR> ................... Switch capture to Linux /dev/dsp mode and 1 scan.
# SOX<CR> .... Switch capture to multi-platform SOund eXchange mode and 1 scan.
# ONE<CR> ...................................... Sets the number of scans to 1.
# TEN<CR> ..................................... Sets the number of scans to 10.
# HUNDRED<CR> .......... Sets the number of scans to 100, (not very practical).
# VER<CR> ............... Displays the version number inside the status window.
# TBVAR<CR> ......... Set up uncalibrated user timebase offset and jump points.
#      SubCommands: ............................. Follow the on screen prompts.
# FASTEST<CR>, SLOWEST<CR> ... Set timebase to the fastest or slowest possible.
# 1mS<CR>, 2mS<CR>, 5mS<CR> ............ Set scanning rate to 1, 2, or 5mS/DIV.
# 10mS<CR>, 20mS<CR>, 50mS<CR> ....... Set scanning rate to 10, 20 or 50mS/DIV.
# 100mS<CR> ................................... Set scanning rate to 100mS/DIV.
# VSHIFT<CR> ........ Set the vertical position from -4 to +4 to the mid-point.
#      SubCommands: ............ Press U or D then <CR> when value is obtained. 
# DRAW<CR> ....... Connect up each vertical plot to give a fully lined display.
# TRIG<CR> ........ Sets the synchronisation methods for storage mode retraces.
#      SubCommand: SYNCEQ<CR> .. Synchronise from a variable, fixed value only.
#      SubCommand: SYNCGT<CR> ......... Synchronise from a positive going edge.
#      SubCommand: SYNCLT<CR> ......... Synchronise from a negative going edge.
#      SubCommand: EXT<CR> ............ SOX ONLY! Follow the on screen prompts.
# SAVEON<CR> ................. Auto-saves EVERY scan with a numerical filename.
# SAVEOFF<CR> ........................... Disables auto-save facility, default.
# ZOOM<CR> ............................. Low signal level gain, ZOOM, facility.
#      SubCommand: 0<CR> ................. Default lowest zoom/gain capability.
#      SubCommand: 1<CR> ............................. X2 zoom/gain capability.
#      SubCommand: 2<CR> ............................. X4 zoom/gain capability.
#      SubCommand: 3<CR> ............................. X8 zoom/gain capability.
#      SubCommand: 4<CR> ............................ X16 zoom/gain capability.
#      SubCommand: <CR> ...... To exit zoom mode when waveform has been viewed.
# HSHIFT<CR> ......... Shift the trace left or right at the highest scan speed.
#      SubCommand: L ........................ Shift the trace left by one byte.
#      SubCommand: l ... Shift the trace left by 64 bytes, (one complete scan).
#      SubCommand: R ....................... Shift the trace right by one byte.
#      SubCommand: r .. Shift the trace right by 64 bytes, (one complete scan).
#      SubCommand: Q or q ........ Exit back to normal usage, (quit this mode).
# RESET<CR> ......................... Do a complete COLD restart of the script.
# FREQ<CR> .. Measure a symmetrical waveform's frequency, accuracy 0.1 percent.
# MODE<CR> Display the X, Y, coupling and mode ranges inside the status window.
# STATUS<CR> . Display the previous status for 3 secs inside the status window.
# LOAD<CR> .................................. Load a binary file for reviewing.
#      SubCommand: ............................... Follow the on screen prompt.
# AC<CR> ......................... Set vertical input to default AC input mode.
# DC<CR> ............................ Attempt to measure DC polarity and level.
# BURST<CR> ........ Play an 8 second sinewave.wav burst using afplay or aplay.
# ARDDET<CR> ................ Detect an Arduino (Diecimila) Board if available.
#      SubCommand: .............................. Follow the on screen prompts.
# ALTDC<CR> ........ Alternate home built DC input device using the sound card.
#      SubCommand: ................................................ UNFINISHED.
# POLARITY<CR> ........... Generate pulse waveforms purely for amplifier tests.
# QTMAC<CR> ........... EXPERIMENTAL MAC, (MBP), QuickTime Player capture mode.
# WINSOUND<CR> ..... Special Windows SoundRecorder.exe for CygWin capture mode.
# ALSA<CR> ................. Special Linux command line, arecord, capture mode.
# SWEEP<CR> .............................. Sweep generator for bandwidth tests.
# SAVE<CR> ............................ Manually save the current scan to disk.
# V<CR> ...... Set the vertical Volts per Division range, (10mV), 100mV to 10V.
#      SubCommand: .............................. Follow the on screen prompts.
# MANUAL<CR>, NOTES<CR> ................................... If in doubt, RTFMs.
#
# !!!Use capture modes QTMAC<CR>, WINSOUND<CR> and ALSA<CR> ENTIRELY AT YOUR
# OWN RISK!!!
#
# Capture modes QTMAC<CR> and WINSOUND<CR> are SSLLOOWW so be well aware!
# ALSA<CR> is primarily for the Linux ALSA sound system machines only.
# There will be potential errors with these capture modes as they have not
# been extensively tested so again, YOU USE THEM ENTIRELY AT YOUR OWN RISK!!!
#
# On quitting the program the current configuration is saved and reused on the
# next program run. Also this AudioScope.Manual and a text mode circuits file
# is saved inside the $HOME drawer\directory\folder.
# End of quick start...
#
# #########################################################
#
# The manual proper:-
# -------------------
#
# Part 1)
#
# Commands in detail:-
# --------------------
#
# <CR> == Carriage Return, RETURN, ENTER key...
#
# <CR> - Pressing the RETURN/ENTER key re-runs a sweep/scan. It re-runs a sweep
# whether in capture mode or hold mode. If in capture mode a completely new
# 1 second snapshot is created. If in hold mode it will re-trace the current
# snapshot, both with the current settings.
#
# RUN<CR> - This enables the capture mode to real and uses one of six inputs,
# /dev/urandom, /dev/dsp, /full/path/to/sox, Windows SoundRecorder.exe, OSX
# QuickTime Player or ALSA arecord.
# The default /dev/urandom, DEMO, startup mode is the best one for getting to
# know how this fun tool works.
# When in REAL capture mode, 'CAPTURE' appears at the top in red.
#
# QUIT<CR> Quits the program, saves your current settings, cleans up your
# terminal window, auto-saves this manual, the quick notes file and the text
# mode circuit diagrams then places you back into the default shell.
#
# HELP<CR> - Show the builtin HELP during the program run. This will
# automatically put the program into HOLD mode, see below.
#
# HOLD<CR> - This disables real capture mode and places AudioScope.sh into
# storage mode so that the last real snapshot can be inspected thoroughly
# using the other builtin commands. It also disables drawing for speed and
# only plots. It will always disable any 'DC' capture mode.
# If drawing is required then it needs to be re-enabled, see DRAW<CR> below.
# When in HOLD mode any red coloured 'CAPTURE' at the top now shows 'STORAGE'
# coloured green.
#
# DEMO<CR>, DSP<CR>, SOX<CR> - These are the 3 main capture modes. DEMO mode is
# the default learning mode. Everything in AC coupling mode works the same as
# in real capture modes but the capture device is /dev/urandom. These re-enable
# real capture, RUN, from any of the 3 sources. Whichever mode is used it is
# autosaved to the configuration file to be used on a program rerun.
# See later in this chapter for 3 more, machine specific, capture modes.
#
# ONE<CR>, TEN<CR>, HUNDRED<CR> - These set the number of continuous
# sweeps/scans. ONE<CR> and TEN<CR> are probably the most useful, HUNDRED<CR>
# is not of much use. These automatically re-enable real capture, RUN, mode.
#
# VER<CR> - Just displays the version number inside the status window.
#
# TBVAR<CR> - Variable timebase speed control. This can set the sweep start
# position, the speed and the end point inside the total number of bytes of
# each capture/store. This will automatically put the program into HOLD mode.
# The sequence of events is as follows:-
#+-----------------------------[COMMAND  WINDOW]------------------------------+
#| COMMAND:- Press <CR> to (re)run, HELP or QUIT<CR> TBVAR                    |
#+------------------------------[STATUS WINDOW]-------------------------------+
#| Stopped...                                                                 |
#| Some status written inside here at any one time.                           |
#+---------------------------------[  OFF  ]----------------------------------+
# Next:-
#+-----------------------------[COMMAND  WINDOW]------------------------------+
#| COMMAND:- Set timebase starting point. From 0 to 47930<CR> 17              |
#+------------------------------[STATUS WINDOW]-------------------------------+
# Next:-
#+-----------------------------[COMMAND  WINDOW]------------------------------+
#| COMMAND:- Set timebase user speed. From 1 to 748<CR> 35                    |
#+------------------------------[STATUS WINDOW]-------------------------------+
# Finally, for a few seconds only, then back to the default stopped state:-
#+-----------------------------[COMMAND  WINDOW]------------------------------+
#| COMMAND:- Press <CR> to (re)run, HELP or QUIT<CR> _                        |
#+------------------------------[STATUS WINDOW]-------------------------------+
#| Scan start at offset 17, with a jump rate of 35.                           |
#| Some status written inside here at any one time.                           |
#+---------------------------------[  OFF  ]----------------------------------+
# ******************** This is the default stopped state. *********************
#+-----------------------------[COMMAND  WINDOW]------------------------------+
#| COMMAND:- Press <CR> to (re)run, HELP or QUIT<CR> _                        |
#+------------------------------[STATUS WINDOW]-------------------------------+
#| Stopped...                                                                 |
#| Some status written inside here at any one time.                           |
#+---------------------------------[  OFF  ]----------------------------------+
#
# FASTEST<CR>, SLOWEST<CR>, 1mS<CR>, 2mS<CR>, 5mS<CR>, 10mS<CR>, 20mS<CR>,
# 50ms<CR>, or 100mS<CR> - Sets the timebase speeds to fixed, known, calibrated
# or extreme values. Whichever timebase range is used it is autosaved to the
# configuration file to be used on a program rerun.
# These will automatically put the program into HOLD mode.
#
# VSHIFT<CR> A pseudo-vertical shift control that moves the trace + or - 4
# vertical _pixels_. This will automatically put the program into HOLD mode.
# The sequence of events as follows:-
#+-----------------------------[COMMAND  WINDOW]------------------------------+
#| COMMAND:- Press <CR> to (re)run, HELP or QUIT<CR> VSHIFT                   |
#+------------------------------[STATUS WINDOW]-------------------------------+
#| Stopped...                                                                 |
#| Some status written inside here at any one time.                           |
#+---------------------------------[  OFF  ]----------------------------------+
# Next:-
#+-----------------------------[COMMAND  WINDOW]------------------------------+
#| COMMAND:- Vertical shift:- U for up 1, D for down 1, <CR> to RETURN:-      |
#+------------------------------[STATUS WINDOW]-------------------------------+
# Next, example, press (uppercase) D:-
#+-----------------------------[COMMAND  WINDOW]------------------------------+
#| COMMAND:- Vertical shift:- U for up 1, D for down 1, <CR> to RETURN:-      |
#+------------------------------[STATUS WINDOW]-------------------------------+
#| Stopped...                                                                 |
#| Vertical shift is -2 from the mid-point position...                        |
#+---------------------------------[  OFF  ]----------------------------------+
# ****************** Finally, to the default stopped state:- ******************
#
# DRAW<CR> - This command will disable real capture when entered manually and
# redraws the current snapshot with the plots connected. When set, it is
# autosaved to the configuration file and on program rerun does NOT disable the
# real capture but restarts in drawing mode. It is set to OFF on the first run
# for slow machines like CygWin so as to run as fast as is possible. The HOLD
# command will disable the drawing facility, see HOLD above for more details.
#
# TRIG<CR> - This searches for a fixed trigger point for a stored waveform so
# as to find a particular part of the waveform for your viewing. It is set to a
# value of 128 and OFF. This will automatically put the program into HOLD mode.
# SubCommands SYNCGT, SYNCLT, EXT will not be mentioned as they are similar.
# Just follow the on screen prompts...
# IMPORTANT NOTE: 'EXT' will only work in 'SOX' capture mode, the other capture
# modes do nothing except return back to the last scan. Use this mode with
# caution as it will sit with a cleared DISPLAY window until the correct
# external value is found and like real machines needs a real signal to work!
# There is a method of exiting this mode via the keyboard and comes up during
# trigger access. It is tricky to use but it does work. The best suggestion I
# can give is not to have the trigger setting(s) too high or too low, OR, not
# use this mode at all!
# The sequence of events is as follows:-
#+-----------------------------[COMMAND  WINDOW]------------------------------+
#| COMMAND:- Press <CR> to (re)run, HELP or QUIT<CR> TRIG                     |
#+------------------------------[STATUS WINDOW]-------------------------------+
#| Stopped...                                                                 |
#| Some status written inside here at any one time.                           |
#+---------------------------------[  OFF  ]----------------------------------+
# Next:-
#+-----------------------------[COMMAND  WINDOW]------------------------------+
#| COMMAND:- Set trigger type, <CR> to disable:- SYNCEQ                       |
#+------------------------------[STATUS WINDOW]-------------------------------+
# Next:-
#+-----------------------------[COMMAND  WINDOW]------------------------------+
#| COMMAND:- Sync point:- U for up 1, D for down 1, <CR> to RETURN:-          |
#+------------------------------[STATUS WINDOW]-------------------------------+
#| Stopped...                                                                 |
#| Synchronisation point set to 147...                                        |
#+---------------------------------[  OFF  ]----------------------------------+
# Next, for a few seconds:-
#+-----------------------------[COMMAND  WINDOW]------------------------------+
#| COMMAND:-                                                                  |
#+------------------------------[STATUS WINDOW]-------------------------------+
#| Synchronisation set to 147, ON and fixed...                                |
#| Synchronisation point set to 147...                                        |
#+---------------------------------[  OFF  ]----------------------------------+
# ****************** Finally, to the default stopped state. *******************
#
# SAVEON<CR>, SAVEOFF<CR> - Enables or disables the autosave facility. When
# enabled it will save EVERY scan whether it is new or a rescan. It uses the
# UNIX style epoch time as the filename with a .BIN extension. There is a test
# file generated during program startup that has the filename 0000000000.BIN
# for test and DEMO purposes. Saving is set to OFF on the very first program
# run and whichever saving mode is set it is saved to the configuration file
# to be used in that mode on program restart.
#
# ZOOM<CR> - This is to display low level AC signals to FSD, (full scale
# deflection). This will automatically put the program into HOLD mode. There
# are five levels of zoom, default 4 bit depth, 5 bit, 6 bit, 7 bit and 8 bit
# depths. They use the current timebase speed and vertical sensitivity. They
# are used for looking at low signal AC component signal levels although they
# could be used for viewing noise on a DC component if required.
# The sequence of events is as follows:-
#+-----------------------------[COMMAND  WINDOW]------------------------------+
#| COMMAND:- Press <CR> to (re)run, HELP or QUIT<CR> ZOOM                     |
#+------------------------------[STATUS WINDOW]-------------------------------+
#| Stopped...                                                                 |
#| Some status written inside here at any one time.                           |
#+---------------------------------[  OFF  ]----------------------------------+
# Next:-
#+-----------------------------[COMMAND  WINDOW]------------------------------+
#| COMMAND:- Set ZOOM gain, (4 = maximum sensitivity), 1, 2, 3 or 4<CR> 1     |
#+------------------------------[STATUS WINDOW]-------------------------------+
# Next:-
#+-----------------------------[COMMAND  WINDOW]------------------------------+
#| COMMAND:- Press <CR> to continue:-                                         |
#+------------------------------[STATUS WINDOW]-------------------------------+
#| 2X zoom/gain state...                                                      |
#| Some status written inside here at any one time.                           |
#+---------------------------------[  OFF  ]----------------------------------+
# ******** Finally, press <CR> to return to the default stopped state. ********
#
# HSHIFT<CR> - This is the horizontal shift control. It is able to display the
# snapshot anywhere inside the whole snapshot file at the fastest possible
# timebase speed only. It is used for viewing possible transient events that
# could be anywhere inside the snapshot. It can do a single byte at a time left
# or right or 64 byte jumps, (one display scan), left or right. On exiting it
# will stay at that horizontal position for zooming, etc, if required.
# This will automatically put the program into HOLD mode.
# The sequence of events is as follows:-
#+-----------------------------[COMMAND  WINDOW]------------------------------+
#| COMMAND:- Press <CR> to (re)run, HELP or QUIT<CR> HSHIFT                   |
#+------------------------------[STATUS WINDOW]-------------------------------+
#| Stopped...                                                                 |
#| Some status written inside here at any one time.                           |
#+---------------------------------[  OFF  ]----------------------------------+
# Next, press L, l, R, r, Q or q:-
#+-----------------------------[COMMAND  WINDOW]------------------------------+
#| COMMAND:- Horizontal shift, press L, l, R, r, (Q or q to exit):-           |
#+------------------------------[STATUS WINDOW]-------------------------------+
#| Horizontal shift, scan start at position 333...                            |
#| Some status written inside here at any one time.                           |
#+---------------------------------[  OFF  ]----------------------------------+
# ******* Finally, press Q or q to return to the default stopped state. *******
#
# RESET<CR> - This command closes the existing running script deleting
# '"$HOME"/AudioScope.Config' and '"$HOME"/AudioScope.tmp/waveform.raw' for a
# complete restart to the default settings.
# ALL files in the '"$HOME"/AudioScope.tmp/' drawer\directory\folder are
# completely overwritten at the moment.
# Note that AudioScope.Config is deleted so any saved parameters will be lost.
# The script is then restarted as though it was a very first time run.
# The list of files generated on each restart are these:-
# Files saved to the '"$HOME"/AudioScope.tmp/' directory.
#
# -rw-r--r--  1 amiga  staff  48000 15 Mar 21:50 0000000000.BIN
# -rwxr-xr-x  1 amiga  staff    609 15 Mar 21:50 1KHz-Test.sh
# -rw-rw-rw-  1 amiga  staff      1 15 Mar 21:50 Arduino_9600.pde
# -rw-rw-rw-  1 amiga  staff      1 15 Mar 21:50 Untitled.m4a
# -rw-r--r--  1 amiga  staff    253 15 Mar 21:50 VERT_BAT.BAT
# -rwxr-xr-x  1 amiga  staff    329 15 Mar 21:50 VERT_DSP.sh
# -rwxr-xr-x  1 amiga  staff    370 15 Mar 21:50 VERT_SOX.sh
# -rw-r--r--  1 amiga  staff      1 15 Mar 21:50 dcdata.raw
# -rw-r--r--  1 amiga  staff  65580 15 Mar 21:49 pulse1.wav
# -rw-r--r--  1 amiga  staff  65580 15 Mar 21:49 pulse2.wav
# -rwxr-xr-x  1 amiga  staff      1 15 Mar 21:50 pulsetest.sh
# -rw-r--r--  1 amiga  staff  48000 15 Mar 21:50 sample.raw
# -rw-r--r--  1 amiga  staff      1 15 Mar 21:50 signed16bit.txt
# -rw-r--r--  1 amiga  staff  65536 15 Mar 21:49 sinewave.raw
# -rw-r--r--  1 amiga  staff  65580 15 Mar 21:49 sinewave.wav
# -rw-r--r--  1 amiga  staff   8000 15 Mar 21:50 squarewave.raw
# -rw-r--r--  1 amiga  staff      1 15 Mar 21:50 sweep.raw
# -rw-r--r--  1 amiga  staff      1 15 Mar 21:50 sweep.wav
# -rw-r--r--  1 amiga  staff  80000 15 Mar 21:50 sweeper.raw
# -rw-r--r--  1 amiga  staff   8000 15 Mar 21:50 symmetricalwave.raw
# -rw-r--r--  1 amiga  staff      1 15 Mar 21:50 symmetricalwave.wav
# -rw-r--r--  1 amiga  staff  48000 16 Mar 11:30 waveform.raw
# -rw-r--r--  1 amiga  staff  65580 15 Mar 21:50 waveform.wav
#
# Files and directory saved in the "$HOME" directory.
#
# -rw-r--r--  1 amiga  staff       1 17 Apr 17:09 AudioScope.Manual
# -rwxr-xr-x  1 amiga  staff  xxxxxx 17 Feb 17:08 AudioScope.sh
# drwxr-xr-x 28 amiga  staff     xxx 10 May 15:51 AudioScope.tmp
# -rw-r--r--  1 amiga  staff       1 17 Mar 17:09 AudioScope_Quick_Start.Notes
# File size "xxxxxx" means it will get bigger as the project progresses.
#
# "dcdata.raw" will always be one byte in size.
#
# "Arduino_9600.pde" will only be FULLY generated when the Arduino Diecimila
# Board is detected. Otherwise one byte in size.
#
# "Untitled.m4a" will only be FULLY generated when capturing using QuickTime
# Player. Otherwise one byte in size.
#
# "pulsetest.sh" will only be FULLY generated in "DEMO" and "/dev/dsp" modes,
# from the "POLARITY" command for CygWin and some Linux flavours. Otherwise one
# byte in size.
#
# "signed16bit.txt" will only be FULLY generated in "CygWin" mode using Windows
# "SoundRecorder.exe" in quiet mode. Otherwise one byte in size.
# (See "Preface:-" for more information.)
#
# "sweep.raw" and "sweep.wav" will only be FULLY generated when the "SWEEP"
# command is activated. Otherwise one byte in size.
#
# "symmetricalwave.wav" will only be FULLY generated when the "FREQ" command
# is activated. Otherwise one byte in size.
#
# These are all of the current files generated for the 'AudioScope.sh' project
# BEFORE the first program 'QUIT<CR>'. Once the program is quitted the
# remaining files are either created and/or modified accordingly.
# "AudioScope.Manual" and "AudioScope_Quick_Start.Notes" are only FULLY created
# on program 'QUIT'. "AudioScope.Config" and "AudioScope.Circuits" are NOT
# created at all UNTIL program 'QUIT'.
#
# FREQ<CR> - This is the builtin LF frequency counter and will measure a
# symmetrical waveform from 50Hz to almost 4000Hz. It CAN be used as stand
# alone if need be but is included ready for the ALTDC hardware/software
# combination. It will be displayed on the bottom line inside the square
# brackets showing 'OFF' in Green. If the counter is accessed for ANY reason
# it will display the frequency for ONE scan only, any scan after that will
# display the counter as 'OFF'. In DEMO mode it will always display '2000 Hz'.
# in Green on Black and White on Black. More to follow later........
#
# MODE<CR> - This command just updates and displays the X, Y, AC/DC, and
# capture modes in the status window at any one time.
#
# STATUS<CR> - This command shows the PREVIOUS status for about 3 seconds. It
# is useful as a reminder of what you previously did as we all suffer from
# short term memory loss sometimes... ;o)
#
# LOAD<CR> - This command loads an existing file, (scan), into memory for
# reviewing. It automatically SAVEs the current scan before loading so be aware
# of this. It also switches any real capture mode to review HOLD mode.
# Follow all on screen prompts to LOAD a required file. The auto-saved file is
# saved as a numerical filename using the 'epoch' time as the filename.
# A successful load will display the following without the quotes:
# "Copying file into storage area..."
#
# AC<CR> - This command ensures AC coupled mode only if NO DC hardware is
# detected or needed. This is the default startup mode and is saved to the
# AudioScope.Config file on program exit.
#
# BURST<CR> - This command generates an 8 second 1KHz sinewave burst using
# aplay for various Linux flavours, afplay for OSX 10.7.5 minimum and requires
# real DSP capture mode for CygWin.
#
# DC<CR> - This command shows a DC result from any attached hardware detecting
# a DC voltage. If no hardware is attached then it defaults to /dev/urandom as
# the default capture. As the ALTDC<CR> command and home built hardware is not
# completed yet then DC<CR> is technically UNFINISHED.
# The DC voltage always shows, 0, zero, for AC coupling and random values in
# DEMO mode. It displays inside the small "[    DC VOLTS   ]" window at the
# bottom of the main scanning window.
# 
# ARDDET<CR> - This is part of DC and detects for the existence of an Arduino
# Diecimila board. This MIGHT work with other USB Arduinos but I have ONLY the
# above one so you try this out completely at your own risk. Thoroughly read
# the code for more information before trying this out. It requires the simple
# FOURTH circuit shown at the end of this file. At the moment it displays 0 to
# + 5.10V DC inside the "[    DC VOLTS   ]" of the bottom of the scanning
# window. Although it works inside CygWin the results may vary. The voltage
# range works as though in 7 bit format and wraps around the same 7 bit range
# values in 8 bit format. It appears the top bit is stripped.
# You may need to install drivers for your Arduino.
# FTDI drivers can be found here:-
# https://www.ftdichip.com/Drivers/VCP.htm
#
# ALTDC<CR> This is UNFINISHED and is a TODO. Running it now gives a starter of
# one of three methods of alternate DC captures. The VCO, (Voltage Controlled
# Oscillator. This code is only accurate to 4 - 5 bit depth but is good enough
# for this fun project. The next method will use a CHOPPER to convert a DC
# signal to a square wave whose amplitude is relative to the DC level. The last
# method, a COUNTER is not even started yet, as of 8th October 2015.
# These methods are not designed to work with CygWin and are mainly
# OSX 10.12.x Macbook Pro 13 inch compliant. They can easily be adapted for
# real Linux and UNIX like machines but that will be for you to develop.
# See ARDDET above for DC access under CygWIn. The DC voltage always shows, 0,
# zero, for AC coupling and random values in DEMO mode. It will ONLY work
# with SOX mode. It displays inside the small "[    DC VOLTS   ]" window at the
# bottom of the main scanning window.
#
# POLARITY<CR> - This command generates two pulse files for the initial setting
# up of the vertical amplifier. They are both unsigned 8 bit, 8KHz sampling
# speed, MONO .WAV files. The CygWin version only works in real DSP capture
# mode. As the hardware used can give conflicting results then both files WILL
# be needed. Read further inside this manual for more information.
#
# QTMAC<CR> **** THIS IS THE CURRENT iMac AND MBP CAPTURE MODE. ***************
# QTMAC<CR> - This command uses the default install Quicktime Player as another
# capture mode. It is not guaranteed to work on every OSX version from
# OSX 10.12.0 onwards so be very, very careful when using this MacOS specific
# capture mode. If you run your iMac or MacBook Pro in Standard User Mode you
# will get three pop-up windows appear in succession. This is a security
# precaution. It will only occur for the VERY first run of this code. Just do
# what is required to enable this capture mode and it will be permanently set.
# !!!YOU USE THIS MODE ENTIRELY AT YOUR OWN RISK!!!
# ************ This section is for OSX 10.7.x only and is disabled. ***********
# You will have to read and edit the code to enable OSX 10.7.x capture mode.
# The code is commented out but still there and it is up to you to change it!
# QTMAC<CR> - This command uses Quicktime as another capture mode. It is
# not guaranteed to work on every OSX version from OSX 10.7.5 onwards so be
# very careful when using this MacOS specific capture mode. YOU USE IT
# ENTIRELY AT YOUR OWN RISK! Quicktime Player MUST be configured to record
# the highest quality 'filename.aifc' format into YOUR "$HOME"/Movies folder.
# ALL 'filename.aifc' files in this folder WILL be deleted on running in this
# mode, so again... !!!YOU USE THIS MODE ENTIRELY AT YOUR OWN RISK!!!
#
# WINSOUND<CR> - This command uses Windows SoundRecorder.exe as another capture
# mode for CygWin. It is for CygWin under Windows Vista and above. It is not
# guaranteed to work on every Windows variant from Vista upwards. There is no
# need to configure SoundRecorder.exe. The only sample rate available is
# 44100Hz and there is a signed 16 bit stereo to unsigned 8 bit mono converter
# built into this code. The calibrated timebase settings are adjusted for the
# closest approximation for this sample speed.
# As Windows 10 no longer has SoundRecorder.exe this mode is now defunct and as
# a result CygWin only has the low resolution '/dev/dsp' mode to use. That is,
# mono, 8 bit, unsigned integer, at 8000 sps basic capture.
# !!!YOU USE THIS MODE ENTIRELY AT YOUR OWN RISK!!!
#
# ALSA<CR> - This switches the capture mode to arecord for Linux machines that
# have the ALSA sound system installed. This is an alternative to SOX but has
# not been thoroughly tested, so be aware.
# !!!YOU USE THIS MODE ENTIRELY AT YOUR OWN RISK!!!
#
# SWEEP<CR> - This creates 'RAW' and 'WAVE" sweep waveform files for bandwidth
# and LF roll-off tests. It is a poor approximation of a variable frequency
# square wave that goes from 4KHz down to about 85Hz and back, twice. It WILL
# have a certain amount of _sinewave_ringing_ on the waveform but this should
# not affect its performance for this requirement.
#
# SAVE<CR> - This just does a single save of the current scan. It disables any
# real capture mode and saves the file as a numerical filename using the
# 'epoch' time as the filename. It does NOT enable the auto-save facility.
#
# V<CR> - This command selects the vertical volts per division range so as to
# be compatible with the hardware connected. If NO amplifier, (and any DC
# adaptor if one exists), is connected then this command can be ignored. This
# parameter is NOT saved to the AudioScope.Config file, so EVERY restart will
# revert the vertical reading to 'Y=Uncalibrated (m)V/DIV' mode.
# The sequence of events is as follows:-
# Firstly adjust the vertical amplifier's gain control to the required level,
# let us say 100mV per division.
# Next from the COMMAND:- window select vertical access:-
#+-----------------------------[COMMAND  WINDOW]------------------------------+
#| COMMAND:- Press <CR> to (re)run, HELP or QUIT<CR>:- V                      |
#+------------------------------[STATUS WINDOW]-------------------------------+
#| Stopped...                                                                 |
#| Some status written inside here at any one time.                           |
#+---------------------------------[  OFF  ]----------------------------------+
# Next from the new refreshed windows as shown:-
#
#This command sets the vertical Volts Per Division, (10mV), 100mV to 10V/DIV.
#Ensure the hardware REQUIRED, (that is the vertical amplifier as a minimum),
#is connected. (If any DC attachment is used also then this is common to both.)
#
#1) ENSURE ANY EXTERNAL HARDWARE REQUIRED IS CONNECTED!
#
#2) Physically change the range on all the hardware connected to be the same.
#
#3) This is either (10mV), 100mV, 1V or 10V. Note that 10mV is only available
#   on machines with that microphone input sensitivity.
#
#4) Enter the range value below and the software will be set correctly to the
#   hardware range physically selected.
#
#+-----------------------------[COMMAND  WINDOW]------------------------------+
#| COMMAND:- Set (m)V/Div. (10mV), 100mV, 1V or 10V<CR> or <CR>:- 100mV       |
#+------------------------------[STATUS WINDOW]-------------------------------+
#| Stopped...                                                                 |
#| Some status written inside here at any one time.                           |
#+---------------------------------[  OFF  ]----------------------------------+
# ****************** Finally, to the default stopped state. *******************
#
# #########################################################
#
# Tools Required:-
# ----------------
#
# 1) Small soldering iron.
# 2) Solder.
# 3) Small side cutters.
# 4) Small long nose pliers.
# 5) _Stanley_ knife or similar.
# 6) 1.2mm drill bit.
# 7) 4mm drill bit.
# 8) Stepped drill bit.
# 9) Lightweight cordless drill.
# 10) Small file set, various shapes.
# 11) Small screwdriver set, various ends.
# 12) Small vice, (OPTIONAL).
# 13) Crimp tool, (OPTIONAL).
# 14) A metal ruler, 12 inches/30 cms long.
# 15) Centre punch, (center punch).
# 16) Sharpened pencil.
# 17) An analogue, (moving coil, 10 to 20K/Volt), multimeter/multitester for
#     the electronic/electrical setups. A digital multimeter will NOT work
#     for one particular setup.
# 18) A hair drier.
#
# #########################################################
#
# Part 2)
#
# First Stage Calibration:-
# -------------------------
#
# From this point on I have to assume that the real capture modes are being
# used as DEMO mode does not need to be calibrated. Also that the script is
# NOT running...
#
# Using the FIRST circuit from the Manual OR the script the first part will
# be built to setup and test the timebase calibration.
# This also contains the parts list for the first build.
#
# Some snapshots and photos of the first and other builds can be found here:-
# https://www.unix.com/shell-programming-and-scripting/212939-start-simple-audio-scope-shell-script.html
# Just follow the thread...
# Many early photos can also be found here also!
# httpss://github.com/wisecracker-bazza/Scope
#
# The First Build:-
# -----------------
#
# (This is aimed at the complete inexperienced, young, amateur.)
#
# Assumptions:-
# -------------
#
# You have a small knowledge of electr(on)ics.
# You can read and understand very basic electr(on)ic circuits.
# You have at least the tools shown above.
# You are at least capable of using those tools above.
# You are willing to learn how to build something different and experiment by
# modifying the code and home built hardware yourself to obtain different
# results and errors.
#
# View the "FIRST extremely simple circuit" near the end of the AudioScope.sh
# script or this AudioScope.Manual. This is text mode but should still be
# easily readable. From now on be very, VERY careful...
#
# (The FIRST extremely simple circuit diagram.)
#
# REFER TO ANY/THE DRAWINGS AND PHOTOGRAPHS!!!
#
# 1) _Stanley_ knife and ruler: Cut a piece of stripboard to give 9 strips by
#    18 holes. Cut at the 10th strip and 19th hole. Cut both sides if necessary
#    as it will not be possible to snap the board in both directions.
# 2) Flat file: File down the jagged edges from 1) to produce smooth edges.
# 3) Cordless drill and 1.2mm drill bit: Open out 4 holes for the green
#    terminal block(s) to be fitted.
# 4) Soldering iron and "legal" solder: Fit the terminal block and solder the 4
#    pins to the board.
# 5) Fit the 2 off 33R resistors, (coded, Orange Orange Black Gold), flat and
#    solder to the board.
# 6) Fit the 2K2 resistor, (coded, Red Red Red Gold), upright and solder to the
#    board.
# 7) Fit the electrolytic capacitor, NOTE the polarity, and solder to the
#    board.
# 8) Finally fit the 1M resistor, (coded, Brown Black Green Gold), upright and
#    solder to the board.
# 9) Side cutters: Trim off all of the excess wire ends.
# 10) Cut the green, yellow, blue and orange wires to about 30cms long each and
#     trim both ends of each by about 3mm.
# 11) Cut the white wire to about 15cms and trim both ends by about 3mm.
# 12) Soldering iron and solder: Tin both ends of these lengths of wire ready
#     for fitting.
# 13) Fit each wire through the board in turn and solder to the board.
# 14) Tie wraps: Tie wrap the wires together for neatness.
# 15) Fit a stick on cable clip to the board and clamp the wires with it.
# 16) The crimp terminal is optional and can be ignored.
# 17) Open up the 4 pole plug.
# 18) Solder each wire to the plug in the correct order. Green goes to the
#     metal body of the plug.
# 19) Check all of your work.
# 20) Check it again!
# 21) Check it a third time, and if you are happy then proceed...
# 22) Re-assemble the plug ready for testing.
#
# Assuming a Macbook Pro OSX 10.7.5, do the first calibration test in this
# order. (For machines with separate Input and Output sockets then it should
# be easy to replace the single 4 pole plug to two stereo 3.5mm jack plugs.)
#
# 1) Build the hardware above first!
# 2) DISCLAIMER! Check and recheck your work AGAIN! Any error may cause harm to
#    your computer and neither myself nor the sites that contain the script
#    will be liable for any damage incurred using the script and attached
#    hardware. See "First Stage Calibration:-" above...
# 3) With an editor of your choice edit the AudioScope.sh file to enable the
#    1KHz audio sinewave generator by removing the '#' at the start of each
#    line as described in the comments near the start.
#    IMPORTANT!!! READ the script first near the start and edit the lines...
#
#    #delay 1
#    #xterm -e "$HOME"/AudioScope.tmp/1KHz-Test.sh &
#
#    ...for the ALL users that have 'xterm' in the executable PATH.
# 4) Now run the AudioScope.sh script and a second "xterm" window will be
#    generated that will continuously run the 1KHz audio sinewave generator in
#    8 second bursts.
# 5) At this point I am assuming you are capturing using the preferred method
#    SOX. This procedure should be the same for all capture modes.
# 6) Inside the AudioScope.sh window enter the command SOX<CR> to enable the
#    capture device, (DSP<CR> if you are just experimenting with Linux).
#    This will take a while as the script searches to find the location of SOX.
# 7) Open up the MBP System Preferences -> Sound window.
# 8) Connect the homebuilt hardware to the mic/ear socket WITHOUT the white
#    flylead being connected to the terminal block.
# 9) Allow a couple of seconds to settle and the Output will switch to
#    Headphones and the Input to External microphone.
# 10) Connect the white flylead to the terminal block as shown in the photos.
# 11) Inside the AudioScope.sh window enter the command TEN<CR> for 10
#     continuous captures.
# 12) Whilst the scans and audio are running adjust the Input and Output levels
#     in the MBP System Preferences -> Sound window. Just press <CR> in the
#     AudioScope.sh command window for another 10 capture scans if required.
# 13) Repeat 12) a few times until a full scale _deflection_ sinewave is
#     obtained. On my machine the mic Input was set to about half way and the
#     Headphones set to about a quarter, (the "Use ambient noise reduction" is
#     unticked).
# 14) Now close down the MBP System Preferences -> Sound window. This will
#     auto-save the Audio Preferences to these settings for future use.
# 15) When in the stopped state AudioScope.sh command window enter the command
#     ONE<CR>.
# 16) Inside the AudioScope.sh window enter the command <CR> only for one scan.
# 17) You might need to repeat 15) for a decent capture.
# 18) Now enter the command HOLD<CR>. This places the AudioScope.sh into
#     storage mode.
# 10) Now enter the command DRAW<CR> and the plotted points will join up.
# 20) Use the command TBVAR<CR>, follow the on screen prompts and set the start
#     anywhere BUT the jump must be 3. This is 500uS/DIV, giving 2 divisions
#     per cycle.
# 21) The peaks or troughs should be spaced two divisions apart...
# 22) Well done! The first hurdle is over.
# 23) Inside the 1KHz xterm window keep pressing Ctrl-C until the window
#     eventually closes down.
# 24) Disconnect the home built hardware, AND, if required......
# 25) Inside the AudioScope.sh window enter QUIT<CR> and quit the program.
# 26) Shut down the terminal and if need be the computer too.
#
# Well done! The first hurdle is over.
#
# #########################################################
#
# Part 3)
#
# Second Stage Calibration:-
# --------------------------
#
# The Second Build:-
# ------------------
#
# (The DC output control board in DC restorer mode.)
#
# Using the THIRD circuit from the Manual OR the script this second part will
# be built to setup the correct display polarity. This is the DC output control
# board unit. This also contains the parts list for the second build.
#
# View the "THIRD extremely simple circuit" near the end of the AudioScope.sh
# script or this AudioScope.Manual. This is text mode but should still be
# easily readable.
#
# (The THIRD extremely simple circuit diagram.)
#
# REFER TO ANY/THE DRAWINGS AND PHOTOGRAPHS!!!
#
# 1) _Stanley_ knife and ruler: Cut a piece of stripboard to give 25 strips by
#    6 holes. Cut at the 26th strip and 7th hole. Cut both sides if necessary
#    as it will not be possible to snap the board in both directions.
# 2) Flat file: File down the jagged edges from 1) to produce smooth edges.
# 3) Small side cutters: Cut short lengths of tinned copper wire and feed
#    through the board as shown in the photos as wired links.
# 4) Soldering iron and "legal" solder: Solder these links into place and trim
#    off any excess copper wire.
# 5) Do the same again for the 2 tinned copper wire, vertical output terminals.
# 6) Fit the three resistors flat, 47K, (coded, Yellow Purple Orange Gold), 1M,
#    (coded, Brown Black Green Gold) and 100K, (coded, Brown Black Yellow
#    Gold) and solder to the board.
# 7) Fit the 1uF capacitor and solder to the board.
# 8) DO NOT fit the 10uF capacitor, C2, at this point. Leave it off of the
#    board until the display polarity calibration has been finished.
# 9) Fit the 2 diodes, NOTE the polarity, (the positions of the bands), and
#    solder to the board.
# 10) Side cutters: Trim off all of the excess wire ends.
# 11) Strip one end of a length of audio coaxial cable and fit a piece of heat
#     shrink sleeving over the braid and another piece over the outer
#     insulation. Trim 3mm of the inner conductor and solder tin the braid and
#     inner conductor ready for fitting.
# 12) Hair drier: Shrink the heat shrink sleeving to give a tidy finish to the
#     cable.
# 13) Soldering iron and "legal" solder: Feed the finished end through the
#     board and solder into place.
# 14) Fit a stick on cable clip to the board and clamp the cable with it.
# 15) Remove the plastic body from the stereo jack plug and slip it over the
#     coaxial cable. Make sure you have the correct way round to refit it!
# 16) Side cutters: Trim off the insulation and trim 3mm off of the inner
#     conductor.
# 17) Soldering iron and "legal" solder: Solder the inner conductor to the tag
#     connected to the plug tip and the braid to the plug barrel/clamp tag.
# 18) Check all of your work.
# 19) Check it again!
# 20) Check it a third time, and if you are happy then proceed...
# 21) Re-assemble the plug ready for testing.
#
# Again, assuming a Macbook Pro OSX 10.7.5, do the second calibration test in
# this order. (For machines with separate Input and Output sockets then it
# should be easy to replace the single 4 pole plug to two stereo 3.5mm jack
# plugs.)
#
# IMPORTANT!!!
# ------------
# It is NOT common knowledge but I discovered that any random machine playing
# an audio file that represented a PULSE waveform would be equally as likely to
# display that pulse waveform on a calibrated Oscilloscope as either positive
# or negative going. So this calibration procedure was required to overcome
# this problem. Under normal music listening tests this would make no
# difference at all but for measuring equipment it is vitally important.
# Because the output polarity has this problem then we HAVE to assume that the
# input source will have the same problem hence this second calibration method.
#
# 1) Build the hardware above first!
# 2) DISCLAIMER! Check and recheck your work AGAIN! Any error may cause harm to
#    your computer and neither myself nor the sites that contain the script
#    will be liable for any damage incurred using the script and attached
#    hardware.
# 3) This is a REAL capture from this machine to show what we are aiming for.
#      +-------+-------+-------+---[CAPTURE]---+-------+-------+--------+
#      |       |       |       |       +       |       |       |        | MAX
#      |       ***     |       |       +       |       |       ***      |
#      |      *|  *    |       |       +       |       |      *|  *     |
#    + +-----*-+---*---+-------+-------+-------+-------+-----*-+---*----+
#      |    *  |   *   |       |       +       |       |    *  |    *   |
#      |    *  |    *  |       |       +       |       |    *  |    *   |
#      |   *   |     * |       |       +       |       |   *   |     *  |
#    0 +-+*+-+-+-+-+-*-+-+-+-+-+-+-+-+-+-+-+-+-**+-+-+-+-+*+-+-+-+-+-*--+ REF
#      | *     |      *|       *****   +    ***| **    | *     |      * |
#      |**     |       *      *|    ***+  **   |   **  | *     |       *|
#      |       |       |*   ** |       ***     |     ****      |        |
#    - +-------+-------+-***---+-------+-------+-------+-------+--------+
#      |       |       |       |       +       |       |       |        |
#      |       |       |       |       +       |       |       |        |
#      |       |       |       |       +       |       |       |        |
#      |       |       |       |       +       |       |       |        | MIN
#      +-------+-------+-------[      OFF      ]-------+-------+--------+
#+-----------------------------[COMMAND  WINDOW]------------------------------+
#| COMMAND:- Press <CR> to (re)run, HELP or QUIT<CR> _                        |
#+------------------------------[STATUS WINDOW]-------------------------------+
#| Stopped...                                                                 |
#| X=Fastest possible, Y=Uncalibrated (m)V/DIV, AC coupled, SOX mode.         |
#+---------------------------------[  OFF  ]----------------------------------+
# 4) At this point I am assuming you are capturing using the preferred method
#    SOX. This procedure should be the same for all capture modes.
# 5) Plug the DC output control board into the mic/ear socket.
# 6) Connect an analogue multimeter to the output terminals, the Red lead to
#    (X), the positive terminal and the Black lead to (Y), _GND_.
# 7) Inside the AudioScope.sh window enter the command POLARITY<CR>
#    (What is required is the LOWEST of two displayed voltages.)
# 8) Follow the on screen prompts that appear. These are at present:-
#    """
#    The THIRD circuit, 'DC output control board', in 'DC restorer mode', IS
#    needed for this second part of the calibration.
#    An analogue multimeter IS also needed for this part of the calibration.
#    Connect the 'DC output control board' to the stereo earphone output.
#    Connect the DC multimeter probes to the output terminals, black to _GND_.
#    Press <CR> and note, A, the FIRST voltage reading:- _
#    Do not disconnect anything yet...
#    Press <CR> and note, B, the SECOND voltage reading:- _
#    The LOWEST voltage reading is the required one so...
#    Press A or B for the LOWEST voltage reading, then <CR> _
#    The polarity variable will need setting to either 0 or 1 manually,
#    either inside this script in the variables section, OR, inside
#    the AudioScope.Config file to produce a positive going pulse...
#    Launching the correct pulse waveform for calibration...
#    Consult the manual for the full setup procedure. <CR> to exit:- _
#    """
#    It is probably better to edit this script as it then becomes dedicated to
#    platform in use and will always be correct for that platform.
# 9) The required positive going pulse generator is detected by the DC output
#    control board, used in DC restorer mode and not as a voltage doubler.
#    Hence the omission of the 10uF capacitor for this section.
# 10) The AudioScope.sh working window will re-appear and a second terminal
#     is launched running the correct positive going pulse waveform.
# 11) Inside the AudioScope.sh window enter the command SOX<CR> to enable the
#     capture device.
# 12) Open up the MBP System Preferences -> Sound window.
# 13) Connect the homebuilt hardware from the 'First Stage Calibration' to the
#     mic/ear socket WITHOUT the white flylead being connected to the terminal
#     block.
# 14) Allow a couple of seconds to settle and the Output will switch to
#     Headphones and the Input to External microphone.
# 15) Connect the white flylead to the terminal block as shown in the photos.
# 16) Inside the AudioScope.sh window enter the command TEN<CR> for 10
#     continuous captures.
# 17) Enter the command DRAW<CR> to ensure that a complete trace is drawn.
# 18) Using your preferred REAL capture mode enter the command RUN<CR>
# 19) Whilst the scans and audio are running adjust the Input and Output levels
#     in the MBP System Preferences -> Sound window. Just press <CR> in the
#     AudioScope.sh command window for another 10 capture scans if required.
# 20) Whilst the system is scanning a positive going pulse is required.
# 21) If it is upside down then exit the second terminal by entering Ctrl-C,
#     then, QUIT<CR> the main script and edit the "polarity" variable inside
#     the main script, OR, the AudioScope.Config file to either 0 or 1. That is
#     if it is 0 then change it to 1 or vice versa.
# 22) Now finally rerun the script and check from 17) again. If all is correct
#     and the displayed pulse is positive going then QUIT<CR> the program and
#     finalise the board.
#
# The Second Build final completion:-
# -----------------------------------
#
# 1) Soldering iron and "legal" solder: Fit the electrolytic capacitor, NOTE
#    the polarity, and solder to the board.
# 2) Side cutters: Trim off all of the excess wire ends.
# 3) Check all of your work.
# 4) Check it again!
# 5) Check it a third time, and if you are happy then proceed...
# The DC output control board in now ready for another addition.
#
# Well done! The second hurdle is over.
#
# #########################################################
#
# Part 4)
#
# The Third Build:-
# -----------------
#
# (The isolated AC coupled ONLY vertical amplifier.)
#
# This will not be as thorough as the other builds as it will entirely depend
# on access to the components within your area or country.
# Refer entirely to the circuit at the end of this script/Manual and any photos
# on the two URLs provided to complete this section.
#
# (The FIFTH simple circuit diagram. REVISION 2.)
#
# REFER TO ANY/THE DRAWINGS AND PHOTOGRAPHS!!!
#
# 1) Decide on the die cast box size you want, mine is 30mm x 60mm x 115mm in
#    size. It is blank and will need to be drilled.
# 2) Use the necessary tools from the 'Tools Required:-' section: Referring to
#    any photographs on the two URL sites in this Manual, mark out and drill
#    the die cast box for fitted parts.
#    A) BNC socket.
#    B) On/Off switch.
#    C) Isolated four pole jack socket.
#    D) LED.
#    E) Stripboard fixing hole.
#    F) Cable exit to the computer, allow for a small insulating rubber
#       grommet.
#    G) Any 'Ground' points, (this may include a flanged BNC socket if you use
#       one).
#    H) Any others that pertain to your method of construction.
# 3) Once built check all of your work thoroughly, recheck again if necessary.
# 4) To get going without vertical calibration connect up as in the "Basic
#    wiring diagram for the vertical deflection amplifier, AC mode only."
#    In uncalibrated mode the unit is now fully functional for AC displays
#    only.
#
# Setting up the vertical amplifier:-
# -----------------------------------
#
# (The FIFTH simple circuit diagram. REVISION 2.)
#
# 1) This can be adjusted in stand alone mode. Remove the four screws and the
#    lid from the die cast box.
# 2) Ensure the power switch is turned OFF.
# 3) Connect the battery.
# 4) Switch the unit ON.
# 5) Allow a few seconds to settle then refer to the circuit diagram below.
# 6) Connect a multimeter across TP1 and the die cast box _GND_, Ground. Red
#    lead to TP1, Black lead to _GND_.
# 7) Set the multimeter to read at least 2.5 Volts.
# 8) A) For the original circuit, (REVISION 1), adjust RV3 to give a voltage
#       across TP1 and _GND_ of +0.85 to +1.00 Volts DC.
#    B) For the current circuit, (REVISION 2), adjust RV3 to give a voltage
#       across TP1 and _GND_ of +2.10 to +2.30 Volts DC.
# 9) Set RV2 roughly to mid point.
# 10) Switch the unit OFF.
# 11) Disconnect the multimeter.
# 12) Refit the lid and screws.
#
# Excellent! This major hurdle is over. If you have gotten this far then you
# are well on the way to becoming an analogue Electronics Engineer. :-)
#
# #########################################################
#
# Vertical Amplifier Calibrator:-
# -------------------------------
#
# Part 5)
#
# (The SECOND extremely simple circuit diagram.)
#
# REFER TO ANY/THE DRAWINGS AND PHOTOGRAPHS!!!
#
# By the time you get to this stage you should be able to construct simple
# stripboard projects without being told or shown where to cut the copper
# tracks so there is no need for me to describe a sequence of events.
#
# As the photograph of the calibration board on the URLs provided uses a
# potentiometer instead of switched ranges then be aware! The switched ranges
# are there for a reason. I used a potentiometer for simplicity only for myself
# because I know how to do it. Use the circuit that is shown below.
#
# How the calibration board works:-
# ---------------------------------
#
# The output from the earphone socket is fed to a step-up audio transformer.
# The output from this transformer is then series fed to two back to back small
# signal silicon diodes via a limiting resistor. This gives a fair
# approximation of a 1.4 Volts Peak to Peak crude squarewave due to the
# forwards voltage drop across each diode of + or - 0.7 Volts about a centre
# point.
# This voltage is then fed to the attenuator to give reasonably accurate levels
# of 10mV, 100mV and 1V peak to Peak, plus a maximum of 1.4V Peak to Peak.
#
# The 10mV range might not be achievable on some machines to be calibrated due
# to the external mic input circuitry designs of any said machine, so be very
# aware of this fact.
#
# #########################################################
#
# The AC condition vertical calibration proper:-
# ----------------------------------------------
#
# Part 6)
#
# You WILL now need two computers to do this task:-
# 1) Your machine that you are calibrating, (in my case my MBP 13 inch).
# 2) A second machine as the signal generator, (in may case my iMac).
# You WILL also need:-
# 3) The vertical amplifier hardware and the/a straight through probe.
# 4) The home built switched calibration hardware.
# 5) A copy of the '"$HOME"/AudioScope.tmp/sweeper.raw' file.
# 6) An installation of SOX on BOTH machines.
#
# The procedure, (primarily for the MacBook Pro 13 inch, OSX 10.7.x):-
# --------------------------------------------------------------------
#
# (This assumes that SOX is already installed on both machines. If not then do
# this as the VERY first thing on both machines. It also assumes that you have
# a copy of ($HOME/)AudioScope.sh on the machine to be calibrated.)
#
# <CR> == Carriage Return Key.
#
# 1) Ensure that both computers are booted up and running. If the second
#    machine has a Windows operating system then so long as SOX is installed
#    this will not be a problem.
# 2) From the machine to be calibrated, open up a terminal and run the script
#    from the '$HOME' directory as ./AudioScope.sh<CR> inside this terminal.
# 3) 'QUIT' the script immediately after the first run.
# 4) Connect the home built vertical amplifier to the mic(/earphone) socket on
#    machine to be calibrated.
# 5) Attach a unity gain probe to the vertical amplifier's BNC socket. (This
#    can be the home built probe; circuit near the end of this manual.)
# 6) Set the External Microphone Level to Normal Maximum. Where this is
#    accessed is entirely dependant on the machine to be calibrated. You will
#    have to find out how to do this for yourself......
# 7) ......Also from this section disable all, (if any), microphone
#    enhancements to ensure the flattest possible passband.
# 8) Switch ON the vertical amplifier.
# 9) Re-start the script from the '$HOME' directory as ./AudioScope.sh<CR>
#    inside the existing terminal. Leave this on stand-by for the time being.
# 10) Copy ("$HOME"/AudioScope.tmp/)sweeper.raw file from the machine to be
#     calibrated to a USB disk drive and transfer it to the second machine;
#     remember where you have saved it on the second machine!
# 11) Now switch to the second machine, the signal generator.
# 12) Ensure the volume setting is at maximum!
# 13) Open up a terminal(/CLI/command_prompt) and FROM the directory where
#     SOX is installed along with sweeper.raw use this command:-
#     ./sox -q -b 8 -r 8000 -e unsigned-integer /path/to/sweeper.raw -d<CR>
#     Change the '/path/to/' to the directory where the sweeper.raw file is.
#     For a Windows machine the command FROM the SOX directory is:-
#     sox -q -b 8 -r 8000 -e unsigned-integer C:\path\to\sweeper.raw -d<CR>
#     Change the 'path\to\' to the directory where the sweeper.raw file is.
#     This will create a single ten second burst of a 2KHz squarewave.
#     This will be loud and will last for 10 seconds, so be very aware.
# 14) Connect the calibration hardware to the second machine's earphone socket.
# 15) You are now ready to calibrate the main machine.
#
# The calibration proper:-
# ------------------------
#
# 1) From the AudioScope COMMAND:- window enter SOX<CR> to find the SOX
#    software.
# 2) Next enter VSHIFT<CR> and using the case sensitive 'U' and on screen
#    prompts shift the trace into the centre of the first upper division scale.
#    The value will be +2.
# 3) Next enter TEN<CR> to set it into ten scans mode.
# 4) Let it do its ten scans and stop, this will take at least ten seconds.
# 5) The signal generator machine is already waiting for the command to
#    generate the ten second squarewave for this calibration.
# 6) Connect the Red crocodile clip of the calibrator to the amplifier's probe
#    tip and the Black crocodile clip to the other Black crocodile clip.
# 7) Set the potentiometer of the amplifier to maximum.
# 8) Set the calibrator to the 10mV range.
# 9) From the signal generator machine enter the sox command shown above at
#    "The procedure, (primarily for the MacBook Pro 13 inch, OSX 10.7.x):-",
#    Part 12), the first command suits UNIX like flavours, including CygWin.
# 10) From the AudioScope COMMAND:- window enter RUN<CR> and it will start
#     scanning at least ten times.
# 11) Adjust the potentiometer until the trace JUST sits on the top and bottom
#     lines of the single division that the trace is scanning in.
# 12) Repeat Parts 9) to 11) until adjusted and then go to Part 13).
# 13) Mark the pointer position of the potentiometer as 10mV. REMEMBER! This
#     sensitivity might NOT be achievable on some machines.
# 14) Set the calibrator to the 100mV range.
# 15) From the signal generator machine enter the sox command shown above at
#    "The procedure, (primarily for the MacBook Pro 13 inch, OSX 10.7.x):-",
#    Part 12), the first command suits UNIX like flavours, including CygWin.
# 16) From the AudioScope COMMAND:- window enter RUN<CR> and it will start
#     scanning.
# 17) Adjust the potentiometer until the trace JUST sits on the top and bottom
#     lines of the single division that the trace is scanning in.
# 18) Repeat Parts 15) to 17) until adjusted and then go to Part 19).
# 19) Mark the pointer position of the potentiometer as 100mV.
# 20) Set the calibrator to the 1V range.
# 21) From the signal generator machine enter the sox command shown above at
#    "The procedure, (primarily for the MacBook Pro 13 inch, OSX 10.7.x):-
#    Part 12)", the first command suits UNIX like flavours, including CygWin.
# 22) From the AudioScope COMMAND:- window enter RUN<CR> and it will start
#     scanning.
# 23) Adjust the potentiometer until the trace JUST sits on the top and bottom
#     lines of the single division that the trace is scanning in.
# 24) Repeat Parts 21) to 23) until adjusted and then go to Part 25).
# 25) Mark the pointer position of the potentiometer as 1V.
# 26) The 10V range cannot be done at this point in time, but if you have come
#     this far then WOW, very, VERY well done!
#
# This project is now a _calibrated_ AC coupled only, AudioScope from around
# 100Hz to 10KHz range. Using the method above you could add a 30mV range,
# 300mV range and in the future a 3V range, giving a 1, 3, 10 sequence.
# The basic accuracy will be about, + or - 5% in the vertical plane due to the
# limitations of:-
# A) The text mode accuracy of 4 bit depth, although the real accuracy in the
#    file(s) is/are at 8 bit depth.
# B) The quality of the vertical amplifier potentiometer.
# c) The parallax accuracy of your marking.
# D) The DRAWing routine/function in this code to display the waveform.
#
# #########################################################
# MUCH MORE TO DO TO THIS MANUAL OVER THE FORESEEABLE FUTURE. This is a TODO.
# #########################################################
#
# The AudioScope.Config file:-
# ----------------------------
#
# demo=0
# drawline=0
# sound_card_zero_offset=-2
# scan_start=1024
# scan_jump=1
# scan_end=47930
# scanloops=0
# setup='Some status written inside here at any one time.'
# save_string='OFF'
# foreground=37
# timebase='Uncalibrated (m)S/DIV'
# polarity=1
# capturemode='DEMO'
# capturepath='/dev/urandom'
#
# These are the autosaved parameters of which one, sound_card_zero_offset=-2,
# HAS to be altered manually. It is set to work on my machines to give a
# straight line along the centre line without glitches. The value can be
# anywhere between + or - 10 to attain this objective. You can either manually
# edit this source code, or the AudioScope.Config file and test by re-running.
# It is probably easier to edit the source code in the variables section.
#
# #########################################################
#
# The files generated during startup and calibrating:-
# ----------------------------------------------------
#
# Files saved to the ""$HOME"/AudioScope.tmp/" directory.
#
# -rw-r--r--  1 amiga  wheel  48000  4 Aug 21:06 0000000000.BIN
# -rwxr--r--  1 amiga  wheel    585  4 Aug 21:06 1KHz-Test.sh
# -rwxr-xr-x  1 amiga  wheel    293  4 Aug 21:08 Arduino_9600.pde
# -rw-r--r--@ 1 amiga  staff  65536  4 Nov 21:08 Untitled.m4a
# -rw-r--r--  1 amiga  wheel    253  4 Aug 21:06 VERT_BAT.BAT
# -rw-r--r--  1 amiga  wheel    303  4 Aug 21:06 VERT_DSP.sh
# -rw-r--r--  1 amiga  wheel    344  4 Aug 21:06 VERT_SOX.sh
# -rw-r--r--  1 amiga  wheel      1  4 Aug 21:06 dcdata.raw
# -rw-r--r--  1 amiga  wheel  65580  4 Aug 21:06 pulse1.wav
# -rw-r--r--  1 amiga  wheel  65580  4 Aug 21:06 pulse.wav
# -rwxr-xr-x  1 amiga  wheel    107  4 Aug 21:07 pulsetest.sh
# -rw-r--r--  1 amiga  wheel  48000  4 Aug 21:06 sample.raw
# -rw-r--r--  1 amiga  wheel 680000  4 Aug 21:06 signed16bit.txt
# -rw-r--r--  1 amiga  wheel  65536  4 Aug 21:06 sinewave.raw
# -rw-r--r--  1 amiga  wheel  65580  4 Aug 21:06 sinewave.wav
# -rw-r--r--  1 amiga  wheel   8000  4 Aug 21:06 squarewave.raw
# -rw-r--r--  1 amiga  wheel  65096  4 Aug 21:07 sweep.raw
# -rw-r--r--  1 amiga  wheel  65140  4 Aug 21:07 sweep.wav
# -rw-r--r--  1 amiga  wheel  32548  4 Aug 21:07 sweeper.raw
# -rw-r--r--  1 amiga  wheel   8000  4 Aug 21:06 symmetricalwave.raw
# -rw-r--r--  1 amiga  staff  20071  4 Aug 21:06 symmetricalwave.wav
# -rw-r--r--  1 amiga  wheel  48000  4 Aug 21:07 waveform.raw
# -rw-r--r--  1 amiga  wheel  65580  4 Aug 21:06 waveform.wav
#
# Files saved in the "$HOME" directory.
#
# -rw-r--r--  1 amiga  staff   xxxxx 17 Apr 17:09 AudioScope.Circuits
# -rw-r--r--  1 amiga  staff  xxxxxx 17 Apr 17:09 AudioScope.Manual
# -rw-r--r--  1 amiga  staff     xxx 17 Apr 17:09 AudioScope.Config
# -rwxr-xr-x  1 amiga  staff  xxxxxx 17 Apr 17:08 AudioScope.sh
# drwxr-xr-x 28 amiga  staff     xxx 10 May 15:51 AudioScope.tmp
# -rw-r--r--  1 amiga  staff    xxxx 17 Apr 17:09 AudioScope_Quick_Start.Notes
# File size "xxxxxx" means it will change as the project progresses.
#
# "dcdata.raw" will always be one byte in size.
#
# Whichever one is selected on test from "pulse1.wav" or "pulse2.wav",
# is RENAMED to "pulse.wav". In this case "pulse2.wav" was selected to give
# "pulse.wav".
#
# These are all of the current files generated for the 'AudioScope.sh' project.
# They are needed in conjunction with home built calibration hardware to
# calibrate this project. AudioScope.sh itself MUST always be in your
# "$HOME" drawer\directory\folder. This shows a listing for ALL possible
# operating conditions on all the platforms that it can run on and with all
# hardware add-ons available for any said platform.
#
# #########################################################
#
# Appendices.
# -----------
#
# Appendix A) MacBook Pro 13 inch, circa August 2012, specific stuff ONLY.
#
# A quick start sub-manual for a MacBook Pro is now saved as:-
#
# ($HOME/)AudioScope_Quick_Start.Notes
#
# ---------------------------------------------------------
# Appendix B) CygWin specific stuff.
#
# For ALL audio generation tests CygWin must be running in /dev/dsp mode.
# The audio generators will not work in any other mode.
# Any other Windows audio playback mode will NOT work!
#
# ---------------------------------------------------------
# Appendix C) Some Linux flavours specific stuff.
#
# Due to the wide choices of installs from various vendors there may be some
# dependencies because they are not installed by default. One such occurrence
# is 'xterm' that is NOT part of a default Linux Mint 17 install.
# in such cases you will have to obtain these from the respective repositories.
# SoX on the other hand is now part of the command line tools in the same OS,
# so there is no need to install Sound eXchange for the main capture for this
# fun project for some, (or maybe all now), Linux installs.
#
# ---------------------------------------------------------
# Appendix D) Other AudioScope script related stuff.
#
# Hidden commands not in the HELP listing:-
# -----------------------------------------
#
# PLAYBACK<CR> - This is hidden because it relies entirely on SoX, (Sound
# eXchange), to be installed. If SOX cannot be found it does nothing but waste
# time trying to find it. This plays back the one second capture 'waveform.raw'
# through the speakers or earphones _IF_ they are connected and/or enabled.
#
# HIRES<CR> - This is also hidden because it relies entirely on SoX. It is used
# to create a high resolution capture for future use. If your device can handle
# a 192000Hz sampling rate AND has SOX installed then it will create a 16 bit,
# unsigned-integer, single channel sample at that 192000Hz sampling rate.
# It will automatically save the current capture as the UNIX epoch time with a
# .BIN extension, as an example:- '1234567890.BIN' ready to reload if required.
# It WiLL overwrite the file 'waveform.raw' with the same filename and does not
# _quantise_ down to 8 bit depth and 48000Hz sampling speed. This is so that
# it can be copied to another device and/or directory and used accordingly.
# This ASSUMES that the sound system inside your device is capable of this
# sampling speed. USE THIS COMMAND completely AT YOUR OWN RISK!!!
#
# SHELL<CR> - This is hidden from the main HELP listing in the running file so
# as to keep it from being used by novices to this program and *NIX. If or once
# you know how to use the shell you can use this to copy some or all of the
# files generated to another place or drive as they are useful for other
# projects. On the current development machine, a MacBook Pro 13 inch, using
# the current OSX at the time of saving, it loads another terminal exactly
# BEHIND the existing AudioScope terminal; it is in the form of a function
# call inside this script.
# The function call is 'NewCLI'.
# Some machines may not have 'xterm' as part of a default install so it will
# become a dependency and would need to be installed so this 'NewCLI' function
# is used instead.
# If CygWin is the UNIX like terminal then a new 'mintty' terminal is launched.
# USE THIS COMMAND COMPLETELY AT YOUR OWN RISK!!!
#
# LIST<CR> - This just lists the generated files only. Any files 1 byte in size
# can be considered as not created because the running of the part of the code
# that uses them have not been user accessed and/or not required for some user
# configurations and machines.
#
# EXIT<CR>, This is a clean quit from the program without saving any of the
# AudioScope.* extra files. It resets the terminal back to startup mode and
# leaves a simple message to say the it has done so.
#
# MANUAL<CR>, NOTES<CR> - This uses the shell tool 'less' so as to be able to
# read the manual whilst the program is running. It uses the same terminal
# window but does NOT mess up the display inside the running program. If 'less'
# is not found then it automatically switches to 'more'.
#
# SPECAN<CR>, This is the built in AF spectrum analyser that has an upper limit
# of 4KHz. This is experimental and generates a stand alone 'bash' script that
# includes a stand alone 'Python' script to do the FFT heavy lifting. It uses
# the built in frequency counter to capture any external signal, otherwise it
# will use AudioScope's internal capture and convert it to a 'WAV' file. The
# files generated are saved into the '/tmp/' drawer and not permanently kept.
# SOX is needed for this to work and CIGWIN is NOT catered for at all.
# !!!YOU USE THIS ADD-ON COMPLETELY AT YOUR OWN RISK!!!
# If you want to extract these files they are:-
# 
# -rw-r--r--  1 amiga  wheel    918  3 Jan 13:11 FFT_WAV.py
# -rwxr-xr-x  1 amiga  wheel   4762  3 Jan 13:11 Spec_An.sh
# -rw-r--r--  1 amiga  wheel   ****  3 Jan 13:11 bash_array
# -rw-r--r--  1 amiga  wheel  48000  3 Jan 13:11 symmetricalwave.raw
# -rw-r--r--  1 amiga  wheel   8044  3 Jan 13:11 symmetricalwave.wav
# The '****' file length varies per the command 'SPECAN' call.
#
# The only important ones are 'FFT_WAV.py' and 'Spec_An.sh'.
# The files 'Spec_An.sh' and FFT_WAV.py are licenced as CC0.
#
# The minimum python version is 2.7.10.
# Python 2.7.10 (default, Feb  6 2017, 23:53:20) 
# [GCC 4.2.1 Compatible Apple LLVM 8.0.0 (clang-800.0.34)] on darwin
# Type "help", "copyright", "credits" or "license" for more information.
# 'scipy' and 'scipy.io' might be dependencies in some Linux flavours as might
# be 'Python' Version 2.7.10 and above. This is totally untested on 'Python'
# Version 3.x.x.
#
# The minimum bash version is 3.2.57.
# GNU bash, version 3.2.57(1)-release (x86_64-apple-darwin16)
# Copyright (C) 2007 Free Software Foundation, Inc.
#
# A typical capture display and matching spectrum display looks like this:-
#                            OSCILLOSCOPE DISPLAY.
#                            ---------------------
#
#      +-------+-------+-------+---[STORAGE]---+-------+-------+--------+
#      |       |       |       |       +       |       |       |        | MAX
#      |       |       |       |       +       |       |       |        |
#      |       |       |*      |       +       |       |       |        |
#    + +-------+*------**------*-------*-------+------*+------*+--------+
#      |*      **      **     **      **       *     **|     **|     *  |
#      | *    ***     ***     **     ***      **    ***|    * *|    **  |
#      | *   * **    * |*    * *    * **    ** *   * **|   *  *|   ***  |
#    0 +-*-+-*-+*+-+-*-+*+-+*+-+*+-+*+-*-+-*-+-*-+-*-+*+-+-*-+*+*+*+-*--+ REF
#      | * **  |*  **  |* ***  |* **   *   *   * **   *|  *   *** *   * |
#      | ****  |* ***  |**     |****   * ***   ****    * **   ** *    * |
#      | ****  | ****  |**     |****   +*      ** *    ** *   **      * |
#    - +-**-*--+--*-*--+**-----+**-*---+-------**------+*-----**------*-+
#      | **    |       |**     | *     +       **      |       *       *|
#      |  *    |       | *     |       +       |*      |       |        |
#      |       |       |       |       +       |       |       |        |
#      |       |       |       |       +       |       |       |        | MIN
#      +-------+-------+-------[      OFF      ]-------+-------+--------+
#+-----------------------------[COMMAND  WINDOW]------------------------------+
#| COMMAND:- Press <CR> to (re)run, HELP or QUIT<CR>:- _                      |
#+------------------------------[STATUS WINDOW]-------------------------------+
#| Stopped...                                                                 |
#| X=5mS/DIV, Y=Uncalibrated (m)V/DIV, AC coupled, SOX mode.                  |
#+---------------------------------[  OFF  ]----------------------------------+
#
#                              SPECTRAL DISPLAY.
#                              -----------------
#
#        ++----[ $VER Spec_An.sh_(C)2017_2020_B.Walker_CC0_Licence. ]-----++
#    100 +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++100
#        ||       |       |       |       |       |       |       |       ||
#     90 ++       +       +       +       +       +       +       +       ++ 90
#  R     ||       |       |       |       |       |       |       |       ||
#  E  80 ++       +       +       +       +       +       +       +       ++ 80
#  L     ||       |       |       |       |       |       |       |       ||
#  A  70 ++   *   +       +       +       +       +       +       +       ++ 70
#  T     ||   *   |       |       |       |       |       |       |       ||
#  I  60 ++   *  *+ **    +       +       +       +       +       +       ++ 60
#  V     ||   *  *| **  * |       |       |       |       |       |       ||
#  E  50 ++   *  *+ **  * +       +       +       +       +       +       ++ 50
#        ||   *  *| **  * |       |       |       |       |       |       ||
#  L  40 ++   *  *+ **  * +   **  +       +       +       +       +       ++ 40
#  E     ||   *  *| ** ** |   **  *       |       |*      |       |       ||
#  V  30 ++ * ****+ ** ** +* ***  *       +       *** *   +* * *  +       ++ 30
#  E     || ******* ** ** ****** **  *  **|*   ** *****  ***** ** |    *  ||
#  L  20 ++ ************* ************* ********* *************** +** **  ++ 20
#Log10(X)||****************************************************************|
#     10 ++****************************************************************+ 10
#        |*****************************************************************|
#      0 +*****************************************************************+ 0
#FREQ Hz +0------500----1000----1500----2000----2500----3000----3500----4000
#                          Press <CR> to continue:-
#
# The vertical scale is relative NOT absolute so be aware of this.
# Both displays are in their own colours.
#
# CLEARALL<CR> - This command clears all the terminal and scroll buffers and
# resets the terminal back to startup state.
#
# -----------------------------------------------------------------------------
# Appendix E) The very first original proof of concept code and display.
#
# This section will NOT be displayed correctly inside an 80 x 24 character
# display. It requires at least a 100 x 24 character display minimum to view!
# <CODE>
#!/bin/bash
#
# AudioScopeDisplay.sh
# 
# This method can also be used for a simple kids level Analogue
# Data_logger/Transient_Recorder.
# Cannot use "setterm -cursor off" as Mac OSX 10.7.5 has not got "setterm",
# so thought of another way for the Macbook Pro... ;o)
#
# $VER: AudioScopeDisplay.sh_Version_0.00.01_Public_Domain_B.Walker_G0LCU.
#
# display()
# {
#	clear
#	graticule="+-------+-------+-------+-------+-------+-------+-------+--------+\n"
#	graticule=$graticule"|       |       |       |       +       |       |       |        |\n"
#	graticule=$graticule"|       |       |       |       +       |       |       |        |\n"
#	graticule=$graticule"|       |       |       |       +       |       |       |        |\n"
#	graticule=$graticule"+-------+-------+-------+-------+-------+-------+-------+--------+\n"
#	graticule=$graticule"|       |       |       |       +       |       |       |        |\n"
#	graticule=$graticule"|       |       |       |       +       |       |       |        |\n"
#	graticule=$graticule"|       |       |       |       +       |       |       |        |\n"
#	graticule=$graticule"+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+--+\n"
#	graticule=$graticule"|       |       |       |       +       |       |       |        |\n"
#	graticule=$graticule"|       |       |       |       +       |       |       |        |\n"
#	graticule=$graticule"|       |       |       |       +       |       |       |        |\n"
#	graticule=$graticule"+-------+-------+-------+-------+-------+-------+-------+--------+\n"
#	graticule=$graticule"|       |       |       |       +       |       |       |        |\n"
#	graticule=$graticule"|       |       |       |       +       |       |       |        |\n"
#	graticule=$graticule"|       |       |       |       +       |       |       |        |\n"
#	graticule=$graticule"|       |       |       |       +       |       |       |        |\n"
#	graticule=$graticule"+-------+-------+-------+-------+-------+-------+-------+--------+\n"
#	printf "$graticule"
# }
#
# while true
# do
#	display
#	for horiz in {2..65}
#	do
#		# Simulate an 8 bit grab and divide by 16 to give 4 bit depth.
#		# Add offset of 2 to allow for missing the top graticule line...
#		vert=$[ ( $RANDOM % ( 256 / 16 ) + 2 ) ]
#		# There IS a FLAW here at _printf_, NOTE, not a bug!
#		# What is it? ;o)
#		printf "\x1B["$vert";"$horiz"fo"
#		# Slow it down so you can see it working...
#		sleep 0.05
#	done
#	printf "\x1B[20;1f"
#	sleep 1
# done
# </CODE>
#
# The continuously changing display...
#
# +-------+-------+-------+-------+-------+-------+-------+--------+
# |       |   oo o|       |       +       |       |       |      o |
# |    o  |       |       |       +       |o      |       |o       |
# |   o   o       |       |       +       |       |       |        |
# +-------+-------+----o-o+-----o-+--o--o-+-------o-------+--------+
# |  o    |       |       |  o    +       o       |    o  |        |
# |       |       |       |       +o      |       |       |        |
# |       |       | o     | o o   o   o   |       |      o|   o    |
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-o+
# |       |       o       |       +       |       |       |        |
# |o     o|  o  o |       |    o  +       |  o  o |       | oo o   |
# |       |       |   o   |       +       |       |       |     o  |
# +-------+-------+-------+-------+----o--+---o---+-o---o-+--------+
# |       |       |o o    |       +      o|       |       |        |
# |       |o      |       o       +       |       |o      |        |
# |       |       |       |o      +       |    o o|  oo   o        |
# | o   o | o     |     o |      o+ o     | o     |       |        |
# +-------+-------+-------+-------+-------+-------+-------+--------+
#
# ********* AudioScope.Manual_2013-2020_Public_Domain_B.Walker_G0LCU. *********
MANUAL
cat << "CIRCUITS" > "$HOME"/AudioScope.Circuits
#
# AudioScope.sh circuits for advanced usage.
# ------------------------------------------
#
# #########################################################
# These circuits are greater than 80 characters per line...
# #########################################################
# The FIRST extremely simple circuit diagram.
# This is a simple I/O board for testing for the Macbook Pro 13 inch...
# It is just as easy to replace the 4 pole 3.5mm Jack Plug with 2 x 3.5mm Stereo Jack
# Plugs for machines with separate I/O sockets.
#                                                       Orange.       White flylead.
# Tip ----->  O  <------------------------------------o---------O <----------o--------+
# Ring 1 -->  H  <-------------------------o-----------)--------O <- Blue.   |        |
# Ring 2 -->  H  <--------------o-----o-----)----------)--------O <- Yellow. |        |
# _Gnd_ --->  H  <----+         |  C1 | +  |          |         O <- Green.  |        |
#           +===+     |         \    ===   \          \         |            \        |
#           |   |     |         /    -+-   /          /         |            /        |
#        P1 |   |     |         \     |    \          \         |            \        |
#           |   |     |      R1 /     | R2 /       R3 /         |         R4 /        |
#            \ /      |         \     |    \          \         |            \        |
#             H       |         /     |    /          /         |            /        |
#            ~~~      |         |     |    |          |         |            |        |
#                     o---------o------)---o----------o---------o------------+        |
# Pseudo-Ground. -> __|__             |                                               |
#            _GND_  /////             +-----------------------------------------------+
# Parts List:-
# P1 ......... 3.5mm, 4 pole jack plug.
# R1 ......... 2K2, 1/8W, 5% tolerance resistor.
# R2, R3 ..... 33R, 1/8W, 5% tolerance resistor.
# R4 ......... 1M, 1/8W, 5% tolerance resistor.
# C1 ......... 47uF, electrolytic, 16V.
# 4 way terminal block.
# Stripboard, (Veroboard), as required.
# Green, yellow, orange, blue, white and tinned copper wire as required.
# Small cable ties, optional.
# Stick on cable clip, optional.
# Crimp terminal, 1 off, optional.
# #########################################################
# The SECOND extremely simple circuit diagram.
# This is the simple vertical calibration HW for this project.
# This uses the dedicated square wave generators for remote machine usage.
# This circuit is isolated from the computer through a transformer.
#                                   R1        1.4VP-P       R2      R3  1VP-P
# Left Channel O/P. O----+    +---/\/\/\---o-----O--------/\/\/\--/\/\/\--O T2
# Tip of 4 pole plug.    |TX1 |            |  T1 |  0.1VP-P R4      R5    |
#                        |    |            |     |  T3 O--/\/\/\--/\/\/\--+
#                         )||(             |     |     |    R6      R7 10mVP-P
#                         )||(          D1 | +   |     +--/\/\/\--/\/\/\--O T4
#                         )||( Primary.  --+-- ,-+-,        R8      R9    |
#              Secondary. )||(o (CT)      / \   \ /    +--/\/\/\--/\/\/\--+
#                         )||(           '-+-' --+--   |
#                         )||(             |  D2 | +   |
#                         )||(             |     |     |
#                        |    |            |     |     |
# Barrel of 4 pole plug. |    |            |     |     |           O/P Common.
# Pseudo-Ground. -> O--o-+    +------------o-----o-----o------------------O T5
#                    __|__
#             _GND_  /////
# Test lead red wire.
# Connect to T1 - T4 <-----------------------------( Red Croc Clip.
# Test lead black wire.
#      Connect to T5 <-----------------------------( Black Croc Clip.
# Parts List:-
# TX1 ........ Audio Output Transformer, example, Maplin P/No:- LB14Q.
# D1, D2 ..... 1N4148, silicon small signal diodes.
# R1 ......... 2K2, 1/8W, 5% tolerance resistor.
# R2 ......... 12K, 1/8W, 5% tolerance resistor.
# R3 ......... 1K5, 1/8W, 5% tolerance resistor.
# R4 ......... 27K, 1/8W, 5% tolerance resistor.
# R5 ......... 3K3, 1/8W, 5% tolerance resistor.
# R6 ......... 2K7, 1/8W, 5% tolerance resistor.
# R7, R8 ..... 330R, 1/8W, 5% tolerance resistor.
# R9 ......... 4R7, 1/8W, 5% tolerance resistor, this can be omitted.
# T1 - T5 .... 5 way terminal block.
# 3.5mm, 4 pole jack plug.
# Stripboard, (Veroboard), as required.
# Red, black and tinned copper wire as required.
# Small cable ties, optional.
# Stick on cable clip, optional.
# 1 Red and 1 Black Croc clip(s) for the test lead.
# #########################################################
# The THIRD extremely simple circuit diagram.
# This is the DC output control board.
# A very simple voltage doubler and passive filter for a controlled DC output.
# This will be used to set and reset a microphone input Analogue to Digital Converter, (ADC).
# Two ARE available and MIGHT be needed, but only ONE for definite.
# (Connect DC OUT & _GND_ to a DC coupled oscilloscope to see it working.)
#
#           Headset O/P.    C1              |\|D2                 X
# Tip only. --> O--------o--||--o-------o---| +---o-------o-------O +VE DC OUT.
#                        |      |       |   |/| + |       |
# Barrel. ----> O        \      | +     \         o       \      IMPORTANT!!! SEE TEXT FOR C2.
#               |        /    --+--     /         | +     /      ------------
#               |     R1 \     / \ D1   \ R2     === C2   \ R3
#               |        /    '---'     /        -+-      /
#               |        \      |       \         |       \ 
#               |        /      |       /         o       /
#               |        |      |       |         |       |       Y
#               +--------o------o-------o---------o---o---o-------O -VE.
#                              Pseudo Ground. ----> __|__
#                                             _GND_ /////
# Parts List:-
# C1 ......... 1 uF, 50V.
# C2 ......... 10 uF, electrolytic, 10V, IMPORTANT! SEE TEXT.
# R1 ......... 33R, 1/8W, 5% tolerance resistor.
# R2 ......... 1M, 1/8W, 5% tolerance resistor.
# R3 ......... 100K, 1/8W, 5% tolerance resistor.
# D1, D2 ..... OA90 or any similar germanium diode.
# 3.2mm standard STEREO jack plug for headset socket.
# Coaxial connecting cable.
# Sundries as required, stripboard, etc, (similar to above).
# #########################################################
# The FOURTH extremely simple circuit diagram.
# Arduino DC input mode to use both polarity modes.
# This simple circuit is ready for the current code for DC measurement from 0 to +5.10 Volts DC.
# Links terminals D and E are ready for virtual ground mode now that the new version of the vertical
# amplifier is released.
# Circuit shown in real ground mode, link B-C connected.
#      DC input, ground. T1 O-------------------------+    A O---+ LINK, A-B or B-C.
# INPUT CCT.                 T2   R1           R2     |          |
#      DC input, see below. O---/\/\/\---o---/\/\/\---o-o----O B o-----o-----+
# LINK A-B or B-C modes.                 |              |    I   |     |     |  e
# A-B is virtual ground mode.            |              |  +-O C |     \     +--o__
# (+ or - 2.55V DC input.)               |              |  |     | +   /        |\    b
# B-C is real ground, default, mode.     |              |  | C1 ===    \ R3   Q1  \|__o--o----------+
# (0 to + 5.10V DC input.)               |              |  |    ---    /          /|     | +        |
#                            T3          |  D        E  |  |     |     \         /   C2 ===         |
#  Arduino, Analog 0 input. O------------o--O        O--+  |     |     /     +--o       ---         |
#                            T4                            |     |     |     |  c        |    R4    |
#     Arduino, true Ground. O------------o-----------------o-----o-----o------)----------o--/\/\/\---)----+
# ARDUINO DEVICE CONNECTIONS.   _GND_  __|__                                 |                      |     |
#                            T5        /////                                 |     R5          RV1 _|_    |
#      Arduino, +5V supply. O------------------------------------------------o------/\/\/\--------/\/\/\--+
# DC test lead red wire.
# Connect to T2 <-----------------------------( Red Croc Clip.
# DC test lead black wire.
# Connect to T1 <-----------------------------( Black Croc Clip.
# Parts List:-
# C1 ......... 47 uF, electrolytic, 10V.
# C2 ......... 10 uF, electrolytic, 10V.
# R1 ......... 2K2, 1/8W, 5% tolerance resistor.
# R2 ......... 100K, 1/8W, 5% tolerance resistor.
# R3 ......... 220R, 1/8W, 5% tolerance resistor.
# R4 ......... 2K2, 1/8W, 5% tolerance resistor.
# R5 ......... 2K7, 1/8W, 5% tolerance resistor.
# RV1 ........ 1K, preset variable resistor.
# Q1 ......... BC548(B), small signal silicon transistor.
# A - E ...... Link terminals.
# Link ....... For A-B or B-C link terminals.
# T1 - T5 .... 5 way terminal block.
# Stripboard, (Veroboard), as required.
# Various coloured and tinned copper wire as required.
# Small cable ties, optional.
# Stick on cable clip, optional.
# 1 Red and 1 Black Croc clip(s) for the test lead.
# #########################################################
# The FIFTH simple circuit diagram. REVISION 2.
# Completely Isolated Vertical Amplifier.
# This simple circuit is merely an impedance changer as the microphone sensitivity is high.
# The photographs show an insulated from _Gnd_ 3.5mm 4 pole chassis mounted socket. This is
# NOT needed and is entirely OPTIONAL.
#                             +----------------o-----------------------------o----o------+
#                             | +              |                             |    |      |
#                         C1 ===               |                             |LED1| +    |
#                            ---             c o                     Preset. \  --+--    |
#                           __|__               \    b           R3      RV3 /   / \ >>> |
#                           /////             Q1 \|__o---o----/\/\/\----o---|\  '---'    |  
#                  Secondary.   Primary.         /|      |              |    /    |      |
# Tip ----->  O     +------+            C2     |/_       | SK1 I/P   C4 | +  \    \      |
# Ring 1 -->  H     |      | T1 +------| H-----o e   C3 ---  +--O)-+   ===   /    /      |
# Ring 2 -->  H  <--+    X |    |         +    |        ---  |  |  |   ---   | R4 \  ZD1 | +
# _Gnd_ --->  H  <--+       )||(               |         |   \  |  |    |    |    /    --+--+
#           +===+   |       )||(      TP1 O----o         |   /  |  |    |    |    \     / \ |
#           |   |   |       )||(               |         |   \  |  +----o----o    /    '---'
#        P1 |   |   | (CT) o)||(               |     RV1 +-->/  |            |    |      |
#           |   |   |       )||(               |  Variable.  \  | TP2        |    o      |
#            \ /    |       )||(               \             /  +--O         | S1  /     |
#             H     |       )||(               /             | Take off to   |    o      |
# Tip.       ~~~    |    X |    | For X, read  \ R2          |   ARDUINO.    |  + |      |
#  ^                |      |    | the Manual.  /             \               |  __|__    |
#  |   Ring 1.      |      \    |              \    Preset.  /               |   ===     |
#  |     ^          |      /    |              /     RV2 +--|\               |    |      |
#  |     |    R5    |   R1 \    |              |         |   /               | BY1|      |
#  |     +--/\/\/\--o      /    |              |         |   \               |  __|__    |
#  |                |      \    |              |         |   /               |   ===     |
#  |                |      /    |              |         |   |               |  - |      |
#  |       R6       |      |    |              |         |   |               |    |      |
#  +-----/\/\/\-----o------+  G O--------------o---------o---o---------------o----o------+
#                             __|__ Diecast box GROUND, (completely isolated from the computer in dedicated AC mode ONLY).
# Parts List:-                /////  GND
# P1 ......... 3.5mm, 4 pole jack plug.
# T1 ......... Audio Transformer, P/No Farnell 1172421.
#              [OEP (OXFORD ELECTRICAL PRODUCTS) - Z1604 - TRANSFORMER, 1:1, 600/600].
#              OR, a salvaged telephone modem isolating transformer, miniature 1:1, 600 Ohms type.
# R1 ......... 2K7, 1/8W, 5% tolerance resistor.
# R2 ......... 820R, 1/8W, 5% tolerance resistor.
# R3 ......... 47K, 1/8W, 5% tolerance resistor.
# R4 ......... 330R, 1/8W, 5% tolerance resistor.
# R5, R6 ..... 33R, 1/8W, 5% tolerance resistor.
# RV1 ........ 1M Log, potentiometer.
# RV2 ........ 2K2K, preset potentiometer.
# RV3 ........ 100K, 10 turn, preset potentiometer.
# C1, C4 ..... 10uF, electrolytic, 16V.
# C2 ......... 1000uF, electrolytic, 6.3V.
# C3 ......... 2.2uF, 50V.
# Q1 ......... BC548B, or any small signal silicon NPN transistor.
# SK1 ........ BNC chassis mounted socket.
# S1 ......... ON/OFF toggle switch.
# LED1 ....... Miniature GREEN LED.
# ZD1 ........ 5.1V Zener diode.
# BY1 ........ PP3 battery.
# PP3 battery connector.
# Diecast box.
# Link terminals, as required.
# Stripboard, (Veroboard), as required.
# Various coloured and tinned copper wire as required.
# Heat shrink sleeving as required.
# Small cable ties, optional.
# Stick on cable clip, optional.
# Crimp ring terminal, for connection to point G.
# Screws, washers, spacers, nuts and grommets as required.
# OPTIONAL 3.5mm 4 pole isolated chassis mounted jack socket.
# #########################################################
# The SIXTH extremely simple circuit diagram.
# This is the PROVISIONAL ALTDC circuit to detect DC to about 200Hz.
#
#                                 R3
#    O/P O-----------------o----/\/\/\----+
#                          |            __|__
#                          |            /////
#                         === C1
#                          |
# LF AC OR      R1         |
# DC I/P O----/\/\/\----o--o--+
#                       |     |
#                       \     o C  Q1
#                       /      \    b
#                    R2 \       \|__o----/\/\/\----O Square wave in from approx 2KHz multivib.
#                       /       /|         R4
#                       \     |/_
#                       /     o e
#                       |     |
#  _GND_ O------o--------)-o--o----o---------------O 0V.
#             __|__     |  |       | +
#             /////     |  O A   --+--
#                       |  I LK1  / \  D1
#                       |  O B   '---'
#   +0.7V, LK1 open.    |  |       |       R5
#   REF  O--------------o--o-------o-----/\/\/\----> +9V.
#   0V LK1 closed.
# Parts List:-
# R1 ......... 1K, 1/8W, 5% tolerance resistor.
# R2 ......... 100K, 1/8W, 5% tolerance resistor.
# R3 ......... 1M, 1/8W, 5% tolerance resistor.
# R4 ......... 22K, 1/8W, 5% tolerance resistor.
# R5 ......... 3K9, 1/8W, 5% tolerance resistor.
# C1 ......... 1uF, 50V capacitor.
# Q1 ......... BC549, or any small signal silicon NPN transistor.
# D1 ......... 1N4148 or any similar silicon diode.
# A, B ....... Link terminals.
# Link ....... For A-B link terminals.
# Stripboard, (Veroboard), as required.
# Various coloured and tinned copper wire as required.
# Small cable ties, optional.
# Stick on cable clip, optional.
# #########################################################
# The SEVENTH extremely simple circuit diagram.
# The DC Control circuit for the ALTDC modes.
# This DC controlled switch is for switching the input of the Y amplifier to
# the output of the ALTDC board and the input to the ALTDC board to the probe.
#                                                                  +------o------+
#                                                                  |      |      |
#                                                                  \      |      |
#                                                                  /      |      |
#  C = Common.             +------O NO                          R3 \    + |      o
# NO = Normally Open.      v                                       /    --+--  S1 /
# NC = Normally closed. NO                                         \  D1 / \     o
#                          ^                                       /    '---'    |
#              C O---o----<o> RLA1 & RLA2 Isolated Contacts.       |      |      |
#                          v                                    +--+--+   |      |
#                       NC ^                     TP1 Optional.  | RLA |   |      | +
#                          +------O NC                 O        +--+--+   |    __|__
#                                                      |        c  |      |     ===
#                                                      |        o--o------+      |
#                        R1     * RV1 Optional.        |  b    /             BY1 |
#  From Trigger  O-----/\/\/\---o---/\/\/\---o------o--o--o__|/  Q1            __|__
# Control Board.                |    ___     |      |        |\                 ===
#                               |     |      |      \         _\|                |
#                               +-----+      | +    /           o--+             |
#                                        C1 ===  R2 \           e  |             |
#                                           ---     /              |             |
#                                            |      \              |             |
#                                            |      /              |             |
#                                            |      |              |             |
#          _GND_ O-----o---------------------o------o--------------o-------------+
#                    __|__
#                    /////
# PartsList:-
# R1 ......... 2K2, 1/8W, 5% tolerance resistor.
# R2 ......... 1M, 1/8W, 5% tolerance resistor.
# R3 ......... 47R, 1/8W, 5% tolerance resistor.
# RV1 ........ 22K preset variable resistor, (* optional).
# C1 ......... 220uF, 10V electrolytic capacitor.
# Q1 ......... BC549, or any small signal silicon NPN transistor.
# D1 ......... 1N4004 or any similar silicon rectifier diode.
# RLA ........ DPDT, 5 Volt coil, relay.
# S1 ......... Miniature ON/OFF switch.
# BY1 ........ PP3 battery.
# PP3 battery connector.
# Link Terminals, as required, (TP1 Optional).
# Stripboard, (Veroboard), as required.
# Various coloured and tinned copper wire as required.
# Small cable ties, optional.
# Stick on cable clip, optional.
# #########################################################
# Basic wiring diagram for the vertical deflection amplifier, AC mode only.
#
# PL1, 4 Pole 3.5mm jack plug inserted into Mic/Ear socket of 13 inch MBP.
#
#           +---------------------+    +-------------------+
#  PL1.     |                     |    |                   |    Probe Tip.
# o===[}----+ Vertical Amplifier. O]---+ Home Built Probe. o--------=>
#           |                     |    |                   o---+
#           +---------------------+    +-------------------+   +----=<
#                                              Crocodile Clip Ground Connector.
# Connect the probe lead to the BNC socket.
# Switch the Amplifier on and use as a variable input level
# #########################################################
# Home built probe 'unity gain' only. This is optional.
# It may be better to buy an existing Oscilloscope Probe.
#
#            CL1.       Body Of Old Ballpoint Pen. (Discard Innards.)
# PL1. Inner Conductor. +--------------+
# (O---------------------)-----------oCI)IH===>  <-- Probe Tip, See Text Below.
# |  +---------------+  +--------------+
# +--+    Screen.    |
#                    |         Crocodile Clip Ground Connector.
#                    +-------------------o====< CC1.
# Parts List:-
# PL1 ........ BNC Plug, 50 Ohm, any type.
# CL1 ........ RG58 coaxial cable. Approximately 1 to 1.5 Metre(s) long.
# CC1 ........ Black crocodile/aligator clip.
# C .......... 3mm Brass screw 25mm long.
# I, I ....... 2 off small 3mm brass washers. One either side of the barrel.
# H .......... 3mm brass nut.
# Heat shrink sleeving as required.
# Old clear bodied ballpoint pen body, all other parts discarded.
# Superglue if required.
#
# There are no construction details except to file a tapered point on the brass screw.
# Solder the inner conductor to the head of the brass screw before assembly.
# #########################################################
CIRCUITS
cat << "QUICKSTART" > "$HOME"/AudioScope_Quick_Start.Notes
#
# MacBook Pro AudioScope.sh uncalibrated, AC only, quick-start information.
# -------------------------------------------------------------------------
#
# First time run of AudioScope.sh:-
# ---------------------------------
#
# <CR> == Carriage Return Key.
#
# Ensure that AudioScope.sh is in your $HOME drawer\directory\folder and once
# there change the access rights to rwxr-xr-x, (755).
# Launch the program from the command prompt as ./AudioScope.sh<CR>
#
# ON FIRST TIME RUN, TYPE QUIT<CR> INSIDE THE BLACK COMMAND WINDOW TO QUIT THE
# PROGRAM IMMEDIATELY. RESTART THE PROGRAM AND _ALL_ FILES WILL HAVE BEEN
# GENERATED.
#
# If you do NOT want to install SOX and ONLY want to capture the internal
# microphone then nothing is needed at all for most systems as of OSX 10.12.4.
# On second time run just type 'HELP<CR>' in the COMMAND window and search for
# another capture mode. You have a choice of QuickTime Player 'QTMAC<CR>',
# for non-ALSA machines that use /dev/dsp 'DSP<CR>', for ALSA machines
# 'ALSA<CR>' using 'arecord' and finally SoundRecorder.exe
# 'WINSOUND<CR>', (IF IT EXISTS), for a CygWin high resolution capture mode
# to use in place of its built-in /dev/dsp 'DSP<CR>'.
# All of these modes, except 'DSP<CR>', WILL be SSLLOOWW to capture a one
# second audio burst. CygWin WILL be SSLLOOWW by default...
# EXCEPT FOR DSP, ALL OF THESE MODES ARE USED ENTIRELY AT YOUR OWN RISK!!!
#
# The initial DEMO mode does almost EVERYTHING that SOX mode does and is
# designed purely as a learning mode.
# AGAIN, if you do NOT want to install SOX and ONLY want to capture the
# internal microphone don't bother to read on, just enjoy messing with this
# fun tool. Just remember that 'HELP<CR>' is always available!
#
# If you want very simple external add-ons to do a little more then read on!
# --------------------------------------------------------------------------
#
# In the running program there is a built-in HELP for all sorts of variables
# that can be used to enhance user experience. Type HELP<CR> from the COMMAND
# window inside the running program.
#
# For FULL information read the AudioScope.Manual, ('MANUAL<CR>' command for
# the FULL manual or the 'NOTES<CR>' command for this quickstart file).
#
# Horizontal time/division calibration is fully valid.
#
# #########################################################
# A very basic MBP test lead for the external microphone input.
# #########################################################
#
# FOR ANY OTHER MACHINE YOU WILL HAVE TO USE THE CORRECT PLUG FOR THE JOB!
#
# A simple test lead with a gain control for a 4 pole MBP microphone socket.
# (If this does not work reliably for you then use 'The FIRST extremely simple
# circuit diagram' inside the main manual and modify that circuit accordingly.)
#
# DANGER!!! DO NOT USE ON DC VOLTAGES GREATER THAN + OR - 15V AND ALWAYS SET
# RV1 TO MINIMUM POSITION FOR EVERY DIFFERENT MEASUREMENT. THIS ALSO APPLIES TO
# ANY AC SIGNAL LEVELS, KEEP THESE TO A MAXIMUM OF 20V P-P AT THE PROBE WITH
# RV1 SET AT MINIMUM GAIN POSITION.
#
# REMEMBER! THIS IS CONNECTED TO THE DELICATE MIC/EAR SOCKET OF THE MACHINE IN
# USE AND COULD CAUSE DAMAGE TO THE INPUT CIRCUIT!!!
#
#                              C1                CL1          CC1
# Tip ----->  O       +-----o--)(--+     +---o---------o--o=====<
# Ring 1 -->  H       |     |      |     |   +---------+
# Ring 2 -->  H  <----+     |      |     \   |  BRAID   \     CC2
# _Gnd_ --->  H  <----+     \      |     /   |           o======<
#           +===+     |     /      |     \   |
#           |   |     |     \  RV1 +---->/   |
#        P1 |   |     |  R1 /            \   |
#           |   |     | SOT \            /   |
#            \ /      |     /       R2   |   |
#             H       |     |   +-/\/\/\-+   |
#            ~~~      |     |   |            |
#                     o-----o---o------------+
# Pseudo-Ground. -> __|__
#            _GND_  /////
# PartsList:-
# R1 ......... SOT, (Select On Test), 2K7 to 6K8, 1/8W, 5% tolerance resistor.
#              Suggested value 2K7.
# R2 ......... 1K, 1/8W, 5% tolerance resistor.
# C1 ......... 100uF, Non Polarised Electrolytic capacitor, 16 Volts.
# RV1 ........ 100K Log, potentiometer.
# CL1 ........ A length of audio co-axial cable.
# CC1 ........ Red crocodile/aligator clip.
# CC2 ........ Black crocodile/aligator clip.
# P1 ......... 3.5mm, 4 pole jack plug.
# Stripboard, (Veroboard), as required.
# Small box to put it all in.
# Knob for gain control.
# Various coloured wire as required.
# Small cable ties, optional.
# Stick on cable clips, optional.
# Heat shrink sleeving as required.
#
# #########################################################
# An MBP specific vertical signal polarity test tool. 
# #########################################################
#
# Vertical volts/division is ignored but the option to correct the polarity
# is shown below.
# Ignore this if you are only observing voice recordings from either internal
# or external microphone sources.
#
# A simple tool to set up the POLARITY if you do NOT have an analogue moving
# coil multimeter. This works on the above machine and might work for you on
# other Apple variants and possibly other machines and platforms too.
#
# Circuit of the POLARITY test plug.
# Tip ----->  O  <-----------+
# Ring 1 -->  H  <--- NC     |       NC = No Connection.
# Body ---->  H  <--+        | LED1
#           +===+   |      .---.
#           |   |   |       \ / >>>
#        P1 |   |   |      --+--
#           |   |   |        | +
#            \ /    |        |
#             H     +--------+
#            ~~~    
# Parts List:-
# P1 ......... 3.2mm standard STEREO jack plug.
# LED1 ....... Small LED
# There are no construction notes as there are only two soldered joints.
#
# Setting up:-
# ------------
# 1) Boot up your MBP 13 inch machine.
# 2) Plug in your test plug and allow a few seconds for it to be detected.
# 3) Start AudioScope.sh as normal.
# 4) Allow a few seconds to settle the type in POLARITY<CR>.
# 5) Go through the on screen sequence of events but instead of detecting the
#    LOWEST voltage you are looking for the HIGHEST brightness of the LED.
# 6) Continue with the on screen prompts and calibrate.
# #########################################################
QUICKSTART
cat "$HOME"/AudioScope.Circuits >> "$HOME"/AudioScope.Manual
cat "$HOME"/AudioScope_Quick_Start.Notes >> "$HOME"/AudioScope.Manual
exit 0
