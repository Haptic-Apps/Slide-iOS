#!/bin/sh
echo "checking for homebrew updates";
brew update
function install_current {
  echo "trying to update $1"
  brew upgrade $1 || brew install $1 || true
  brew link $1
}
if [ -e "Mintfile" ]; then
  install_current mint
  mint bootstrap
fi
