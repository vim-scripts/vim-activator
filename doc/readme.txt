Purpose

There's a script that comes with vim distribution for editing with existing
vim in Windows.  However, this feature doesn't work in Linux xterm
environment.  There's a beast called Vim Shell by Thomas Wana, but it's not
officially endorsed by vim.  When you exit vim to shell by pressing <ctrl-z>
which suspends the vim, this nifty little gadget allows you edit subsequent
files by reusing the existing vim.  It's kind of emulates a vim shell from the
view point of a normal user.  This tool requires client-server option to be
enabled in vim.

The only tested platform is my box, which is SuSE Linux 11.1 with konsole.  If
you have any problems, please contact me at yiuwingyipAT126DOTcom.

Enjoy and feel free to improve the script and C code ;-)

Installation Instruction

1.	Put .bash_profile into your home directory.  If there's already existing
one, then you can the renamed the untar file to a different name, and source
it from the existing .bash_profile.

2.	Change the path to vimactivator in .bash_profile line 2 according your
current setting.
