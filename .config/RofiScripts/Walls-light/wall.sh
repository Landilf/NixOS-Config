#! /bin/sh

: "${LC_ALL:=C.UTF-8}"
: "${LANG:=C.UTF-8}"
export LC_ALL LANG

DIR="$HOME/.config/RofiScripts/Walls-light/Walls"

back_label="← Back"

selected=$(
		{
			printf "%s\n" "$back_label"
			ls "$DIR" | while read -r A; do
				echo -en "$A\x00icon\x1f$DIR/$A\n"
			done
		} | rofi -dmenu -i -config "$HOME/.config/RofiScripts/WallpaperChanger/WC.rasi" -kb-move-char-back "" -kb-move-char-forward "" -kb-custom-1 "Left" -kb-accept-entry "Control+j,Control+m,Return,KP_Enter,Right"
	)
	rc=$?

if [ "$rc" -eq 10 ] || [ "$selected" = "$back_label" ]; then
	~/.config/RofiScripts/WallpaperChanger/WallMenu.sh
	exit 0
fi

[ -z "$selected" ] && exit 0

matugen image "$DIR/$selected" -m light -t scheme-fidelity --fallback-color grey
ln -sfn "$DIR/$selected" ~/.config/RofiScripts/Walls-light/Wall
ln -sfn "$DIR/$selected" ~/.config/RofiScripts/WallpaperChanger/Wall
~/.config/nwg-dock-hyprland/launch.sh
