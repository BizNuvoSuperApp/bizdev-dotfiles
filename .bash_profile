# .bash_profile

if [ -f ~/.local/bin/updot ]; then
    ~/.local/bin/updot
fi

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi

JAVA_HOME=~/.local/jdk-21
PATH="$PATH:$HOME/.local/bin:$JAVA_HOME/bin"

eval "$(oh-my-posh init bash --config quick-term)"

# User specific environment and startup programs
