#! /bin/sh

: "${LC_ALL:=C.UTF-8}"
: "${LANG:=C.UTF-8}"
export LC_ALL LANG

back_label="← Back"

	chosen=$(
		{
			printf "%s\t\n" "$back_label"
			cliphist list
		} | rofi -dmenu -display-columns 2 -config "$HOME/.config/RofiScripts/Clipboard/CB.rasi" -kb-move-char-back "" -kb-move-char-forward "" -kb-custom-1 "Left" -kb-accept-entry "Control+j,Control+m,Return,KP_Enter,Right"
	)
	rc=$?

if [ "$rc" -eq 10 ] || [ "$chosen" = "$back_label" ]; then
	~/.config/RofiScripts/Launcher/Launcher.sh
	exit 0
fi

[ -z "$chosen" ] && exit 0
printf "%s" "$chosen" | cliphist decode | wl-copy
