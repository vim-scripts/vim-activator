# path to the activator relative to home
vimactivator="$HOME/.vim/public/activator/activator"
$vimactivator

# Reuse existing vim as much as possible.
function reusevim()
{
	vimbin="/usr/bin/vim"
	# The following only works in xterm
	if [[ $TERM != "xterm" ]]
	then
		$vimbin $1
		return
	fi

	path=`pwd`
	file=$path/$1
	# Don't add current directory for network files.
	if [[ $1 =~ "://" ]]
	then
		file=$1
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
	jobno=`jobs | grep vimbin | sed "s/\[\([[:digit:]]\+\)\].*/\1/"`
	if [[ $jobno == '' ]]
	then 
		# no instance is running in the background, start the default one
		$vimbin --servername VIM$$ $file
	else
		$vimactivator $$ $file
		if [ $? -eq 0 ]
		then
			fg $jobno
		else
			# Something wrong with the binary, so use the default vim.
			$vimbin --servername VIM$$ $file
		fi
	fi
}

alias vi=reusevim
