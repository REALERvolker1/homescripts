# My zsh config

This is my current zsh config.

I have been trying to get better with documentation, since I often end up referring this repo to both new and old zsh users alike.

## .zshenv

This is loaded every time my zsh scripts are loaded. At the time of this README, it just has prompt settings in it.

## .zprofile

This is loaded every time I log in. It has some important login stuff, including environment variables.

## environ.zsh

This used to be my vlkenv script, and I used to try and keep it POSIX-compliant because I used to use dash as my login shell. However, since I use zsh as my login shell now, I sort of migrated it over. Anyways, this is full of shell-fixing and XDG environment variable and PATH setting goodness.

## .zshrc

Lots of documentation in this file. This loads a bunch of stuff that I need for my interactive shell.

## rc.d

These are a bunch of startup scripts that I source from my zshrc. The ones ending in *.defer.zsh are lazily-loaded after zle starts.

### 10-environment

This is a bunch of useful environment-related stuff I thought didn't really fit the vibe of environ.zsh

### 15-zsh-defer

This is basically a local copy of zsh-defer I keep to have a stable API that I update on my own terms

### 20-completion

These are my completion settings

### 30-keybinds

These are my keybinds, as well as several useful zle widgets I almost entirely made myself.

### 40-vlkprompt.zsh

This is my shell prompt. At the moment, I am trying to find some way to have the same features, but make the code actually good and clean and performant. This is why I have a folder called [vlkprompt](vlkprompt-old) that has a bunch of failed attempts in it

### 80-aliases

These are my shell aliases, as well as some other useful shell functions. This one was migrated from my old shared bash/zsh setup, so it has some residual hallmarks of that.

### 90-plugins

This is my plugin manager. If there's one script that will help you understand why I like my setup the most, it's that one

## functions

These are all shell functions that are autoloaded. My editor doesn't know what to make of them, but some of them are pretty useful, like [__cd_ls](functions/__cd_ls)

### command_not_found_handler

This function will search for a command if I don't have it installed. It asks me first, of course! I hate it when people write handlers that just automatically search dnf for like 10 seconds every single time I type "ekesrubgkyuabekrga" into my command line and hit enter, which I do quite often.

### __which__function

This is a wrapper around `whence` that I want to run when I run `which` in the terminal. It does a lot of formatting, colorizing, etc. and shows me a lot of info about stuff. I really like this one, and it's a good candidate for rewriting in rust as a zsh module.

### recompile

This function will compile my zsh config into bytecode, to be stored in zsh's shared memory and loaded Blazingly Fast™🚀

## modulesrc/modules

These are zsh modules -- dynamic libraries written in rust that I can load into zsh. As the [crate](https://github.com/Diegovsky/zsh-module-rs) I use to do this is still very prototype-y, I don't really rely on these.

## settings

This is a bunch of old stuff I don't really use anymore, but my syntax highlighting theme is in there I guess. I should probably go through this folder one of these days.

## site-functions

These are a bunch of completion definitions I kinda just have

## vlkprompt-old

These are a bunch of failed attempts at rewriting my prompt better.

## zsh-plugins

This is a symlink to my zsh plugin directory. I just have it here for my own convenience.

