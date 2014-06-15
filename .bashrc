#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

export PATH=$PATH:/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games

export LANG=en_US.UTF-8
export EDITOR="vim"
export synclient VertEdgeScroll=1

# for setting hist`ory length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1500
HISTFILESIZE=3000
# don't put duplicate lines in the history. See bash(1) for more options
HISTCONTROL=ignoredups

# check the window size after command and, if necessary,
# update the values of LINES and COLUMNS
shopt -s checkwinsize

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    alias ls='ls  --color=auto'
    alias ll='ls -lh --color=auto'
    alias la='ls -la --color=auto'
    alias lla='ls -lha --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

#function irc()
#{
#    if [ "$TMUX" == "" ]
#    then
#      
#    if [ "$(tmux ls | grep irssi)" == "" ]
#        then
#            echo "todo apagado, prende tmux y irssi"
#            tmux new-session -s irssi irssi
#        fi
#            echo "no esta tmux abierto en la terminal pero si irssi en una session tmux, attacha esa sesion con tmux"
#            tmux attach -t irssi
#
#    else
#
#       if [ "$(tmux ls | grep irssi)" != "" ]
#        then
#            echo "tmux esta abierto y no existe la session de irssi, crea la session"
#            
#            tmux switch -t irssi
#        fi
    #        echo "tmux esta abierto y la session tambien, cambia a la session irssi"
     #       tmux switch -t irssi
      #      irssi
#echo "NO IRSSI SESSION! :/"

#fi
#}
#alias irssi='OLD_TMUX=$TMUX;TMUX="";tmux new-session -s irssi irssi;TMUX=OLD_TMUX'

function ccd()
{
    cd $1
    echo "$(pwd)" > ~/.lastcd
}
alias cd='ccd'
alias lcd='cd "$(cat ~/.lastcd)"'

alias pcolors='( x=`tput op` y=`printf %$((${COLUMNS}-6))s`;for i in {0..256};do o=00$i;echo -e ${o:${#o}-3:3} `tput setaf $i;tput setab $i`${y// /=}$x;done; )'

#alias mocp="mocp --theme trasparent-background"
export TERM=xterm-256color

# On branch this return the branch name else '(no branch)'.
function get_git_branch()
{
    branch_name="$(git symbolic-ref HEAD 2> /dev/null | sed -e 's/refs\/heads\///')"

    if [[ "$branch_name" != "" ]]; then
        echo -n "$branch_name"
    else
        echo -n "(no branch)"
    fi
}

function get_git_progress()
{
    # Detect in-progress actions (e.g. merge, rebase)
    # https://github.com/git/git/blob/v1.9-rc2/wt-status.c#L1199-L1241
    git_dir="$(git rev-parse --git-dir)"

    # git merge
    if [[ -f "$git_dir/MERGE_HEAD" ]]; then
        echo " [merge]"
    elif [[ -d "$git_dir/rebase-apply" ]]; then
        # git am
        if [[ -f "$git_dir/rebase-apply/applying" ]]; then
            echo " [am]"
        # git rebase
        else
            echo " [rebase]"
        fi
    elif [[ -d "$git_dir/rebase-merge" ]]; then
        # git rebase --interactive/--merge
        echo " [rebase]"
    elif [[ -f "$git_dir/CHERRY_PICK_HEAD" ]]; then
        # git cherry-pick
        echo " [cherry-pick]"
    fi
    if [[ -f "$git_dir/BISECT_LOG" ]]; then
        # git bisect
        echo " [bisect]"
    fi
    if [[ -f "$git_dir/REVERT_HEAD" ]]; then
        # git revert --no-commit
        echo " [revert]"
    fi
}

function is_branch1_behind_branch2 ()
{
    # $ git log origin/master..master -1
    # commit 4a633f715caf26f6e9495198f89bba20f3402a32
    # Author: Todd Wolfson <todd@twolfson.com>
    # Date:   Sun Jul 7 22:12:17 2013 -0700
    #
    #     Unsynced commit

    # Find the first log (if any) that is in branch1 but not branch2
    first_log="$(git log $1..$2 -1 2> /dev/null)"

    # Exit with 0 if there is a first log, 1 if there is not
    [[ -n "$first_log" ]]
}

function branch_exists ()
{
    # List remote branches           | # Find our branch and exit with 0 or 1 if found/not found
    git branch --remote 2> /dev/null | grep --quiet "$1"
}

function parse_git_ahead ()
{
    # Grab the local and remote branch
    branch="$(get_git_branch)"
    remote_branch="origin/$branch"

    # $ git log origin/master..master
    # commit 4a633f715caf26f6e9495198f89bba20f3402a32
    # Author: Todd Wolfson <todd@twolfson.com>
    # Date:   Sun Jul 7 22:12:17 2013 -0700
    #
    #     Unsynced commit

    # If the remote branch is behind the local branch
    # or it has not been merged into origin (remote branch doesn't exist)
    if (is_branch1_behind_branch2 "$remote_branch" "$branch" ||
          ! branch_exists "$remote_branch"); then
        # echo our character
        echo 1
    fi
}

function parse_git_behind ()
{
    # Grab the branch
    branch="$(get_git_branch)"
    remote_branch="origin/$branch"

    # $ git log master..origin/master
    # commit 4a633f715caf26f6e9495198f89bba20f3402a32
    # Author: Todd Wolfson <todd@twolfson.com>
    # Date:   Sun Jul 7 22:12:17 2013 -0700
    #
    #     Unsynced commit

    # If the local branch is behind the remote branch
    if is_branch1_behind_branch2 "$branch" "$remote_branch"; then
        # echo our character
        echo 1
    fi
}

function parse_git_dirty()
{
    # If the git status has *any* changes (e.g. dirty), echo our character
    if [[ -n "$(git status --porcelain 2> /dev/null)" ]]; then
        echo 1
    fi
}

function get_git_status()
{
    # Grab the git dirty and git behind
    dirty_branch="$(parse_git_dirty)"
    branch_ahead="$(parse_git_ahead)"
    branch_behind="$(parse_git_behind)"

    # Iterate through all the cases and if it matches, then echo
    if [[ "$dirty_branch" == 1 && "$branch_ahead" == 1 && "$branch_behind" == 1 ]]; then
        echo "⬢"
    elif [[ "$dirty_branch" == 1 && "$branch_ahead" == 1 ]]; then
        echo "▲"
    elif [[ "$dirty_branch" == 1 && "$branch_behind" == 1 ]]; then
        echo "▼"
    elif [[ "$branch_ahead" == 1 && "$branch_behind" == 1 ]]; then
        echo "⬡"
    elif [[ "$branch_ahead" == 1 ]]; then
        echo "△"
    elif [[ "$branch_behind" == 1 ]]; then
        echo "▽"
    elif [[ "$dirty_branch" == 1 ]]; then
        echo "*"
    fi
}

function is_on_git()
{
    git rev-parse 2> /dev/null
}

function print_git_info()
{
    tput setaf 233
    tput setab 235
    echo -n ""
    tput setaf 28
    echo -n " "
    tput setaf 24
    tput bold
    echo -n "$(get_git_branch)"
    tput setaf 202
    echo -n "$(get_git_status)"
    tput sgr0
    tput setaf 235
    echo -n ""
    tput sgr0
}

#
# others functions
#

function isD_w()
{
    IFS=' ' data=($(ls -l -d $(pwd)))
    if [[ "${data[0]:8:1}" == "w" || ( "${data[2]}" == "$(whoami)" &&  "${data[0]:2:1}" == "w"  ) || ( "${data[3]}" == "id -g -n $(whoami)" && "${data[0]:5:1}" == "w") ]]
    then
        echo "can write"
    else 
        echo "can't write"
    fi
}

function print_location()
{
    spwd="$(pwd)"
    IFS='/' folders=($spwd)

    fristfolder=${folders[@]:1:1}
    length=${#folders[@]}
    lastpos=$(($length - 1))
    lastfolder="${folders[$lastpos]}"

    for f in ${folders[@]}
    do
        if [ "$f" = "$lastfolder" ]
        then
            tput bold
            tput setab 233
            tput setaf 242

            if [ "$(isD_w)" == "can't write" ] 
            then
                tput setaf 160
                echo -n " "
            fi 

            tput setaf 255
            echo -n " $lastfolder"

            tput sgr0
            tput setaf 233
            echo ""
        elif [ "$f" != "" ]
        then
            tput setab 233
            tput setaf 242
            echo -n " $f "
            tput setaf 236
            echo -n ""
        fi
    done
    tput sgr0
}

function print_user()
{

    CountJobs=$(jobs | wc -l)

    if [ $CountJobs != 0 ]
    then
        tput setab 24
        tput setaf 233
        echo -n "$CountJobs"
    fi

    tput setab 233
    tput setaf 24
    echo -n ""
    tput bold
    tput setab 233
    if [ $(id -u) == 0  ]
    then
        tput setaf 160
    else 
        tput setaf 166
    fi
    echo -n "$(whoami)"
    if [ "$(cat ~/.socr.bash)" == "0" ]
    then
        tput setaf 34
        echo -n "✔"
    else
        tput sgr0
        tput setab 233
        tput setaf 236
        echo -n ""
        tput setab 233
        tput setaf 88
        echo -n "$(cat ~/.socr.bash)"
        tput setaf 160
        echo -n "✘"

    fi 
    tput sgr0
    tput setaf 233
    !(is_on_git) && echo -n ""

    tput sgr0
}

function save_old_comand_result()
{
   echo "$?" > ~/.socr.bash
}

PS1="\$(save_old_comand_result)\$(print_location)\$(print_user)\
\$(is_on_git && print_git_info)
"
