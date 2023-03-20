#!/usr/bin/env bash
export EDITOR="$EDITOR --create-frame"

e () {
    if ! test -S $XDG_RUNTIME_DIR/emacs/server; then
	if test -n $WAYLAND_DISPLAY; then
	    systemctl start --user emacs
	fi
    fi
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

Nr () {
    local mode="${1}"
    local dir="$(pwd)"
    if test -z "${mode}"; then
	echo "rebuild nixos from flake inside $dir"
	echo "no build mode specified"
	echo "use 'boot' or 'switch'"
	return 1
    else
	cd $HOME/nixos-config
	if test -f $dir/flake.nix; then
	    doas nixos-rebuild $mode --flake "git+file://${dir}"
	else
	    echo "no flake.nix found in $dir"
	    return 1
	fi
    fi
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
	 $(which ffmpeg) -device /dev/dri/card0 \
	 $fps \
	 -f kmsgrab \
	 -i - \
	 -vf 'hwmap=derive_device=vaapi,scale_vaapi=format=nv12' \
	 -c:v h264_vaapi \
	 -qp 24 $filename
EOF
	# see this link for more ffmpeg video encoding options
	# https://ffmpeg.org/ffmpeg-codecs.html#VAAPI-encoders
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

nmail () {
    notmuch tag +flagged tag:flagged +passed tag:passed
    notmuch tag -unread tag:passed
    mbsync -a
    notmuch new
    if ! test -f $HOME/.config/tubpass; then
	pass show de/uni/tub | head -n1 > $HOME/.config/tubpass
    fi
}

mcreate_symblink () {
    local source=${1%:*}
    local target=${1#*:}
    if ! test -L "${target}"; then
	if test -d "${target}"; then
	    # rm dir created by home-manager
	    rm -rf "${target}"
	fi
	if test -e "${source}"; then
            ln -s "${source}" "${target}"
	fi
    fi
}

msymlinks="
/oldroot${HOME}/Downloads:${HOME}/Downloads
/oldroot${HOME}/Documents:${HOME}/Documents
/oldroot${HOME}/Maildir:${HOME}/Maildir
/oldroot${HOME}/nixos-config:${HOME}/nixos-config
/oldroot${HOME}/.gnupg:${HOME}/.gnupg
/oldroot${HOME}/.ssh/authorized_keys:${HOME}/.ssh/authorized_keys
/oldroot${HOME}/.ssh/known_hosts:${HOME}/.ssh/known_hosts
/oldroot${HOME}/.ssh/yc:${HOME}/.ssh/yc
/oldroot${HOME}/.ssh/tub_latex_repokey:${HOME}/.ssh/tub_latex_repo_key
/oldroot${HOME}/.password-store:${HOME}/.password-store
${HOME}/.config/w3m:${HOME}/.w3m"
### script on login
if [ "$(tty)" = "/dev/tty1" ]; then
    set -e
    for mount in $msymlinks; do
	mcreate_symblink $mount
    done
    set +e
fi

bootstrap="
/oldroot${HOME}
/oldroot${HOME}/Downloads:${HOME}/Downloads
/oldroot${HOME}/Documents:${HOME}/Documents
/oldroot${HOME}/Maildir:${HOME}/Maildir
/oldroot${HOME}/.gnupg:${HOME}/.gnupg
/oldroot${HOME}/.ssh/
"

mauthorizedKey () {
    mkdir -p $HOME/.ssh
    echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINN0Jghx8opezUJS0akfLG8wpQ8U1rdZZw/e3v+nk70G yc@yc-eb820g4" >> $HOME/.ssh/authorized_keys
}

mbootstrap () {
    local choice
    echo "you need to run this in a SUBSHELL. type YES if you know"
    read choice
    if [ "$choice" != "YES" ]; then
	return 1
    fi

    set -ex
    local source=""
    for mount in $bootstrap; do
	source="${mount%:*} ${source}"
    done
    doas /usr/bin/env source="${source}" user=$(whoami) bash <<-'EOF'
set -ex
for i in $source; do
    if ! test -d "${i}"; then
     mkdir -p "${i}"
   fi
   chown -R  ${user}:users /oldroot/home
set -ex
done
EOF
    if test -f $HOME/.ssh/yc && ! test -f /oldroot/$HOME/.ssh/yc; then
	cp $HOME/.ssh/yc /oldroot/$HOME/.ssh/yc
	chmod u=rw,go= /oldroot/$HOME/.ssh/yc
	chmod u=rw,go= $HOME/.ssh/yc
    elif ! test -f $HOME/.ssh/yc && ! test -f /oldroot/$HOME/.ssh/yc; then
	echo "ERROR: private ssh key yc not found!!!"
	return 1
    fi
    echo "clone password repo"
    git clone tl.yc:~/githost/pass /oldroot${HOME}/.password-store
    echo "clone sysconf repo"
    git clone tl.yc:~/githost/dotfiles-flake /oldroot${HOME}/nixos-config
    git -C /oldroot${HOME}/nixos-config checkout personal
    echo "restore gnupg"
    scp tl.yc:~/gpg.tar.xz  /oldroot${HOME}
    tar -axC /oldroot${HOME} -f /oldroot/${HOME}/gpg.tar.xz
    rm $HOME/.ssh/yc
    for mount in $msymlinks; do
	mcreate_symblink $mount
    done
    mkdir -p $HOME/Maildir/apvc.uk
    echo "EXIT_SUCCESS"
    set +ex
}
