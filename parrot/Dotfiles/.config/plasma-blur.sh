#!/usr/bin/env sh

# Usage:
# ./plasma-blur.sh 'command' 'class' [transparency level]
# E.g.:
# $ ./plasma-blur.sh 'code' 'Code' 3

# Run in background
eval "$1 &"

# Blur
i=0
while [ "$i" -lt 18 ]; do
        if [ "$i" -lt 6 ]; then
                sleep 0.1s
        else
                sleep 0.2s
        fi
        xdotool search -classname "$2" | xargs -I{} xprop -f _KDE_NET_WM_BLUR_BEHIND_REGION 32c -set _KDE_NET_WM_BLUR_BEHIND_REGION 0 -id {}
        i=$((i + 1))
done

# Transparent
i=0
while [ "$i" -lt "$3" ]; do
        qdbus org.kde.kglobalaccel /component/kwin org.kde.kglobalaccel.Component.invokeShortcut "Decrease Opacity"
        i=$((i + 1))
done

