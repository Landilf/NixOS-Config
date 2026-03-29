#! /bin/sh

: "${LC_ALL:=C.UTF-8}"
: "${LANG:=C.UTF-8}"
export LC_ALL LANG

back_label="← Back"

chosen=$(
	printf "%s\n" \
		"$back_label" \
		"󱓞 Autostart" \
		"󰪫 Environment" \
		"󰍽 Input" \
		"󰌌 Keybindings" \
		" Look and Feel" \
		"󰍹 Monitors" \
		" Permissions" \
		" Programs" \
		" Plugins" \
		"󰆍 Scripts" \
		" Windows and Workspaces" \
		"󰥛 Animations (Variables!)" \
		"󰘇 Decoration (Variables!)" |
		rofi -dmenu -i -selected-row 1 -config "$HOME/.config/RofiScripts/SystemSettings/S_hyprland.rasi" -kb-move-char-back "" -kb-move-char-forward "" -kb-custom-1 "Left" -kb-accept-entry "Control+j,Control+m,Return,KP_Enter,Right"
)
rc=$?

if [ "$rc" -eq 10 ] || [ "$chosen" = "$back_label" ]; then
	~/.config/RofiScripts/SystemSettings/system.sh
	exit 0
fi

case "$chosen" in
   "󱓞 Autostart") codium ~/.config/hypr/hyprconfigs/hyprautostart.conf ;;
   "󰪫 Environment") codium ~/.config/hypr/hyprconfigs/hyprenvironment.conf ;;
   "󰍽 Input") codium ~/.config/hypr/hyprconfigs/hyprinput.conf ;;
   "󰌌 Keybindings") codium ~/.config/hypr/hyprconfigs/hyprkeybinds.conf ;;
   " Look and Feel") codium ~/.config/hypr/hyprconfigs/hyprlookandfeel.conf ;;
   "󰍹 Monitors") codium ~/.config/hypr/hyprconfigs/hyprmonitors.conf ;;
   " Permissions") codium ~/.config/hypr/hyprconfigs/hyprpermissions.conf ;;
   " Programs") codium ~/.config/hypr/hyprconfigs/hyprprograms.conf ;;
   " Plugins") codium ~/.config/hypr/hyprconfigs/hyprplugins.conf ;;
   "󰆍 Scripts") ~/.config/RofiScripts/SystemSettings/scripts.sh ;;
   " Windows and Workspaces") codium ~/.config/hypr/hyprconfigs/hyprwindowsandworkspaces.conf ;;
   "󰥛 Animations (Variables!)") codium ~/.config/hypr/hyprconfigs/hypranimations.conf ;;
   "󰘇 Decoration (Variables!)") codium ~/.config/hypr/hyprconfigs/hyprdecoration.conf ;;
   *) exit 1 ;;
esac
