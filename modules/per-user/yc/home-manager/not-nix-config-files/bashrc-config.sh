#!/usr/bin/env bash

e () {
    $EDITOR "${@}"
}

tm () {
    tmux attach-session
}

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
    if test -n $fps; then 	fps="-framerate $fps"; fi
    doas /usr/bin/env sh <<EOF
        umask ugo=rw && \
	 ffmpeg -device /dev/dri/card0 \
	 $fps \
	 -f kmsgrab \
	 -i - \
	 -vf 'hwmap=derive_device=vaapi,scale_vaapi=format=nv12' \
	 -c:v h264_vaapi \
	 -qp 24 $filename
EOF
	# see this link for more ffmpeg video encoding options
	# https://ffmpeg.org/ffmpeg-codecs.html#VAAPI-encoders
    fi
}

gm () {
    printf "laptop brightness: b\n"
    printf "gammastep:         g\n"
    printf "laptop screen:     s\n"
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

### script on login
if [ "$(tty)" = "/dev/tty1" ]; then
    set -ex
    set +ex
fi
