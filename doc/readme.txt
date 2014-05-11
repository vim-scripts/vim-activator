Purpose

There's a script that comes with vim distribution for editing with existing
vim in Windows.  However, this feature doesn't work in Linux xterm
environment.  There's a beast called Vim Shell by Thomas Wana, but it's not
officially endorsed by vim.  When you exit vim to shell by pressing <ctrl-z>
which suspends the vim, this nifty little gadget allows you edit subsequent
files by reusing the existing vim.  It's kind of emulates a vim shell from the
view point of a normal user.  This tool requires client-server option to be
enabled in vim.

I've added redefined bash commands that make you feel like work on a vim shell
(and yes it's just the vanilla bash) which is currently ranking as the number
one item on the feature requested list.

The tested platforms are my moutain lion macbook and linux workstation, which
is SuSE 11.1 with konsole.  If you have any problems, please contact me at
yiuwingyipAT126DOTcom.

Enjoy and feel free to improve the script and C code ;-)

Installation Instruction

1.	Put .bash_profile into your home directory.  If there's already existing
one, then you can rename the untar file to a different name, and source
it from the existing .bash_profile.

2.	Change the path to vimactivator in .bash_profile line 2 according your
current setting.

3.	Copy Shell to .vim directory.

4.	In .vimrc so Shell.vim.

----------------- Redefine Bash Commands ---------------------------------
cd
	When we're using vim, we can use <c-z> to pause the current vim session
	and resume using bash.  Once you're on the bash command line, type "cd"
	the first time will go to the home directory, but the second time it'll go
	to the vim buffer's directory.  This behaviour can let you switch to the
	buffer's working directory smartly.

exit
	When you have vim running at the background, i.e, after hitting <c-z> in
	vim, it's annoying when you exit the shell but bash complain there's
	background job.  This redefined version of "exit" will quit bash cleanly
	if the background vim has no modified buffers.  However, if there's
	modified buffer, then vim will be brought to foreground.

fg
	If the current background job is vim, then it'll brought it to the
	foreground and highlight the current char as block cursor.

vi
	This command will reuse the background vim and loading the current buffer
	as the input file.  Also it'll highlight the current char as block cursor.

As a side note, I'm using Terminal on macbook with the underline blinking
cursor as the terminal preferences, and the customised cursor highlight from
my script works nicely with the above "cd", "fg" and "exit" commands which
allows me to spot the cursor very quickly when switing from bash command line
to vim.
