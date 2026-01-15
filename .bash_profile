# .bash_profile

if [ -f ~/.local/bin/updot ]; then
    ~/.local/bin/updot
fi

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi

JAVA_HOME=$HOME/.local/jdk-21
PATH="$PATH:$JAVA_HOME/bin"

eval "$(oh-my-posh init bash --config froczh)"

# User specific environment and startup programs
