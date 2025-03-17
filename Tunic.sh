#!/bin/bash

if [ -d "/opt/system/Tools/PortMaster/" ]; then
  controlfolder="/opt/system/Tools/PortMaster"
elif [ -d "/opt/tools/PortMaster/" ]; then
  controlfolder="/opt/tools/PortMaster"
else
  controlfolder="/roms/ports/PortMaster"
fi

source $controlfolder/control.txt
[ -f "${controlfolder}/mod_${CFW_NAME}.txt" ] && source "${controlfolder}/mod_${CFW_NAME}.txt"
get_controls

# Variables
GAMEDIR="/$directory/windows/tunic"
EXEC="Tunic.exe"

# CD and set log
cd $GAMEDIR
> "$GAMEDIR/log.txt" && exec > >(tee "$GAMEDIR/log.txt") 2>&1

# Display loading splash
$ESUDO $GAMEDIR/splash "$GAMEDIR/splash.png" 30000 & 

# Exports
export SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig"
export WINEDEBUG=-all

export BOX64_DYNAREC_SAFEFLAGS=1
export BOX64_DYNAREC_FASTNAN=1
export BOX64_DYNAREC_FASTROUND=1
export BOX64_DYNAREC_X87DOUBLE=0
export BOX64_DYNAREC_BIGBLOCK=3
export BOX64_DYNAREC_STRONGMEM=0
export BOX64_DYNAREC_FORWARD=512
export BOX64_DYNAREC_CALLRET=1
export BOX64_DYNAREC_WAIT=1
export BOX64_AVX=0
export BOX64_MAXCPU=8
export BOX64_UNITYPLAYER=1

# Determine architecture
if file "$GAMEDIR/data/$EXEC" | grep -q "PE32" && ! file "$GAMEDIR/data/$EXEC" | grep -q "PE32+"; then
    export WINEARCH=win32
    export WINEPREFIX=~/.wine32
elif file "$GAMEDIR/data/$EXEC" | grep -q "PE32+"; then
    export WINEPREFIX=~/.wine64
else
    echo "Unknown file format"
fi

# Install dependencies
if ! winetricks list-installed | grep -q "^dxvk2041$"; then
    pm_message "Installing dependencies."
    winetricks dxvk2041
fi

# Config Setup
mkdir -p $GAMEDIR/config
bind_directories "$WINEPREFIX/drive_c/users/root/AppData/LocalLow/Andrew Shouldice/Secret Legend" "$GAMEDIR/config"

# Run the game
$GPTOKEYB "$EXEC" -c "$GAMEDIR/tunic.gptk" &
box64 wine "$GAMEDIR/data/$EXEC"

# Kill processes
wineserver -k
pm_finish