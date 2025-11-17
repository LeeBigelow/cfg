#!/bin/sh

# initial setup
# git init --bare $HOME/.cfg
# alias cfg='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'
# cfg config --local status.showUntrackedFiles no

# setup alias
alias cfg='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'

echo "Remember to add this alias to your shell:"
echo "alias cfg='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'"
echo

# clone and check out 
git clone --bare https://github.com/LeeBigelow/cfg.git $HOME/.cfg
if cfg checkout; then
	echo "Checked out config.";
else
	echo "Backing up pre-existing dot files to ~/.config-backup and retrying.";
	mkdir -p $HOME/.config-backup
	cfg checkout 2>&1 | egrep "\s+\." | awk {'print $1'} | xargs -I{} mv {} $HOME/.config-backup/{}
	cfg checkout
fi
cfg config status.showUntrackedFiles no

