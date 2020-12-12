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
# Install gems if a Gemfile exists
if [ -e "Gemfile" ]; then
  echo "installing ruby gems";
  # install bundler gem for ruby dependency management
  gem uninstall bundler
  gem install bundler:1.17.3 --no-document || echo "failed to install bundle"; #1.17.3 is needed for other deps
  gem install danger --no-document || echo "failed to install danger";
  
  bundle config set deployment 'true';
  bundle config path vendor/bundle;
  bundle install || echo "failed to install bundle";
fi

