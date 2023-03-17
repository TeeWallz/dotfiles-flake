#!/usr/bin/env bash

yc_create_symlinks () {
    local source_list="${1}"
    local target_list="${2}"
    local counter=1
    local source=$(echo $source_list | cut -d' ' -f $counter)
    while test -n $source; do
	local target=$(echo $target_list | cut -d' ' -f $counter)
	if ! test -L "${target}"; then
	    ln -s "${source}" "${target}"
	fi
	counter=$(( $counter + 1 ))
	source_list=$(echo $source_list | cut -d' ' -f ${counter}-)
	target_list=$(echo $target_list | cut -d' ' -f ${counter}-)
    done
}

yc_my_symlinks_source="$HOME/.config/w3m"
yc_my_symlinks_target="$HOME/.w3m"
yc_my_symlinks_source_home="Downloads Documents systemConfig .gnupg .ssh"
for i in $yc_my_symlinks_source_home; do
    yc_my_symlinks_source="$yc_my_symlinks_source /oldroot/home/yc/$i"
    yc_my_symlinks_target="$yc_my_symlinks_target /oldroot/home/yc/$i"
done
yc_create_symlinks $yc_my_symlinks_source $yc_my_symlinks_target

y () {
    mpv -v "${@}"
}

nix-reformat () {
    git ls-files | grep nix$ | while read i; do nixfmt $i; done
}

doa ()
{
    doas -s
}

watchtex () {
    if test -z "${1}"; then
	echo "watch a tex file and auto-compile pdf when modified"
	echo "no file specified"
	return 1
    else
	latexmk -cd -interaction=nonstopmode -pdf -pvc "${1}"
    fi
}

wfr () {
    local choice
    local fps
    local filename
    filename=$HOME/Downloads/$(date +%Y%m%d_%H%M%S).mp4
    fps="1"
    printf "frame rate? default 1fps\n"
    printf "enter n to use normal frame rate\n"
    printf "enter 60 to force 60fps\n"
    read choice
    if test "$choice" = "n"; then
	fps=""
    fi
    if test "$choice" = "60"; then
	fps="60"
    fi
    printf "do not run as root and use KMSgrab?\n"
    printf "this is fast, use GPU only, but no mouse cursor\n"
    printf "see https://trac.ffmpeg.org/wiki/Hardware/VAAPI\n"
    printf "if no, enter n\n"
    read choice
    if test "$choice" = "n" ; then
	if test -n $fps; then fps=",fps=$fps"; fi
	wf-recorder \
	    -c h264_vaapi \
	    -d /dev/dri/renderD128 \
	    -F format=nv12,hwupload${fps} \
	    -f $filename
    else
	if test -n $fps; then 	fps="-framerate $fps"; fi
	doas /usr/bin/env sh <<EOF
 umask ugo=rw && \
 ffmpeg -device /dev/dri/card0 \
 $fps \
 -f kmsgrab \
 -i - \
 -vf 'hwmap=derive_device=vaapi,scale_vaapi=format=nv12' \
 -c:v h264_vaapi \
 -qp 24 \
$filename
EOF
	# see this link for more ffmpeg video encoding options
	# https://ffmpeg.org/ffmpeg-codecs.html#VAAPI-encoders
    fi
}

gm () {
    printf "laptop brightness: b\n"
    printf "gammastep:         g\n"
    printf "laptop screen:     s\n"
    printf "fix mon res:       m\n"
    local choice
    read choice
    case $choice in
	b)
	    printf "set minimum: m\n"
	    printf "set percent: p PERCENT\n"
	    local percent
	    read choice percent
	    case $choice in
		m)
		    brightnessctl set 3%
		    ;;
		p)
		    brightnessctl set ${percent}%
		    ;;
	    esac
	    ;;
	g)
	    printf "monitor dim day:   md\n"
	    printf "monitor dim night: mn\n"
	    printf "laptop  dim night: ld\n"
	    printf "reset:             r\n"
	    read choice
	    case $choice in
		md)
		    (gammastep -O 5000 -b 0.75 &)
		    ;;
		mn)
		    (gammastep -O 3000 -b 0.56 &)
		    ;;
		ld)
		    (gammastep -O 3000 &)
		    ;;
		r)
		    pkill gammastep
		    (gammastep -x &)
		    pkill gammastep
		    ;;
	    esac
	    ;;
	s)
	    printf "disable: d\n"
	    printf "enable:  e\n"
	    read choice
	    case $choice in
		d)
		    swaymsg  output eDP-1 disable
		    swaymsg  output LVDS-1 disable
		    ;;
		e)
		    swaymsg  output eDP-1 enable
		    swaymsg  output LVDS-1 enable
		    ;;
	    esac
	    ;;
	m)
	    swaymsg output DP-2 mode 3840x2160@30Hz scale 2
	    ;;
    esac
}

tubb () {
    if ! test -f $HOME/.config/tubpass; then
	pass show de/uni/tub | head -n1 > $HOME/.config/tubpass
    fi
    wl-copy < $HOME/.config/tubpass
}

# functions defined here will not be shown in autocomplete
# but they works
nmail () {
    mkdir -p /home/yc/Documents/non/Maildir/apvc.uk/
    notmuch tag +flagged tag:flagged +passed tag:passed
    notmuch tag -unread tag:passed
    mbsync -a
    notmuch new
    if ! test -f $HOME/.config/tubpass; then
	pass show de/uni/tub | head -n1 > $HOME/.config/tubpass
    fi
}
