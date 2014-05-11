# path to the activator relative to home
vimactivator="$HOME/.vim/public/activator/activator"

# absolute path to vim
vimbin="/usr/bin/vim"

# This is a fake file and it's used to trigger BufEnter event.
# It's used by Shell.vim internally.
exiter="$HOME/.vim/.shellexit.sh"

# run the activator on startup
$vimactivator

# Reuse existing vim as much as possible.
function reusevim()
{
	# The following only works in xterm
	term=`echo $TERM | sed 's/\(xterm\).*/\1/'`
	if [[ $term != "xterm" ]]
	then
		$vimbin $1
		return
	fi

	# Don't add current directory for network files.
	if [[ $1 =~ "://" ]]
	then
		file=$1

	# This is an absolute path.
	elif [[ $1 =~ ^/ ]]
	then
		file=$1

	else
		path=`pwd`
		file=$path/$1
		file=`echo $file | sed 's/~/$HOME/g'`
	fi

	# Auto expand the file name to various source files if possible.
	if [ ! -f $file ]
	then
		if [ -f $file"c" ]
		then
			file=$file"c"

		elif [ -f $file"java" ]
		then
			file=$file"java"

		elif [ -f $file".java" ]
		then
			file=$file".java"

		elif [ -f $file"xml" ]
		then
			file=$file"xml"

		fi
	fi

	# get the job number for previous vi
	jobno=`jobs | grep vimbin | sed "s/\[\([[:digit:]]*\)\].*/\1/"`
	if [[ $jobno == '' ]]
	then 
		# no instance is running in the background, start the default one
		$vimbin --servername VIM$$ $file
	else
		# just to let the server to see the change, this is needed on mac
		echo $$ > /dev/null

		# send the ppid and file name to the forwarder
		$vimactivator $$ $file
		if [ $? -eq 0 ]
		then
			builtin fg $jobno
		else
			# Something wrong with the binary, so use the default vim.
			$vimbin --servername VIM$$ $file
		fi
	fi
}

# Highlight the current char as block cursor for vim.
function foreground()
{
	jobno=`jobs | head -n 1 | grep vimbin  | sed "s/\[\([[:digit:]]*\)\].*/\1/"`
	if [[ $jobno != '' ]]
	then
		$vimbin --servername VIM$$ -u NONE -U NONE --remote-send "<C-\\><C-N>:silent<space>call<Space>ShowBlockCursor(0)<cr><c-l>"
	fi
	builtin fg
}

# Redefine cd to work better with vim.
function smartcd()
{
	# keep the old way of doing things...
	if [[ ! -z $1 ]]
	then
		builtin cd "$1"
		return
	fi

	# Use vim history to get the directory name cookie,
	# which has the format "VIMXXX directory_name"
	tempdir=$($vimbin -u ~/.vimrc -e -s none << EOF 
	s/^/\=histget("expr", -1)/
	print
	quit
	EOF)
	# Split the cookie to get the actual directory name, etc.
	PARTS=( $(IFS=" " echo "$tempdir") )

	if [ -z ${PARTS[0]} ]
	then
		builtin cd
		return
	fi

	# This is not from vim server.
	if [ ${PARTS[0]} != "VIM"$$ ]
	then
		builtin cd
		return
	fi

	# FIXME: delete the vim history. However, if we enable this then we can't have
	# 'cd' act like toggling between home directory and the current directory.
	# deleteHistory=$($vimbin -u ~/.vimrc -e -s none << EOF 
	# s/^/\=histdel("expr", -1)
	# quit
	# EOF)

	currdir=`pwd`
	# same directory then just go to the home directory
	if [ ${PARTS[1]} == $currdir ]
	then
		builtin cd
		return
	fi

	# go to the directory only when it's really a directory
	if [ -d ${PARTS[1]} ]
	then
		builtin cd "${PARTS[1]}"
	else
		builtin cd
	fi
}

# Redefine exit so that we can exit the shell cleanly, even vim is running at
# the background, when vim has no modified buffers.
function shellexit()
{
	jobno=$(jobs | grep vimbin | sed "s/\[\([[:digit:]]*\)\].*/\1/")
	if [[ $jobno == '' ]]
	then
		builtin exit
	else
		# just to let the server to see the change, this is needed on mac
		echo $$ > /dev/null

		# start editing the fake file which will trigger BufEnter event in vim
		$vimactivator $$ $exiter

		if [ $? -eq 0 ]
		then

			before=$(date "+%s")
			fg $jobno # bring vim back to foreground
			now=$(date "+%s")

			diff=$(expr $now - $before)
			# If the vim has been reactive for more than two seconds, 
			# we won't call exit.
			if [[ $diff -lt 2 ]]
			then
				shellexit # do it again, there's no more vim
			fi
		else
			builtin exit
		fi
	fi
}

alias vi=reusevim
alias cd=smartcd
alias exit=shellexit
alias fg=foreground
