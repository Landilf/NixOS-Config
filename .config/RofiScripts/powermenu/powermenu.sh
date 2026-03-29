#! /bin/sh

: "${LC_ALL:=C.UTF-8}"
: "${LANG:=C.UTF-8}"
export LC_ALL LANG

back_label="← Back"

	chosen=$(
		printf "%s\n" \
			"$back_label" \
		"󰐥" \
		"󰜉" \
		"󰒲" \
		"󰌾" \
		"󰀄" |
		rofi -dmenu -i -selected-row 1 -config "$HOME/.config/RofiScripts/powermenu/P.rasi" -kb-move-char-back "" -kb-move-char-forward "" -kb-custom-1 "Left" -kb-accept-entry "Control+j,Control+m,Return,KP_Enter,Right"
	)
	rc=$?

if [ "$rc" -eq 10 ] || [ "$chosen" = "$back_label" ]; then
	exit 0
fi

case "$chosen" in
   "󰐥") poweroff ;;
   "󰜉") reboot ;;
   "󰒲") systemctl hibernate ;;
   "󰌾") hyprlock ;;
   "󰀄") hyprctl dispatch exit ;;
   *) exit 1 ;;
esac
