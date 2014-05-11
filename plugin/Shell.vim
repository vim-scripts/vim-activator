if exists("ShellSourced")
	finish
endif 
let ShellSourced = "true"

" ---------------------------- exit helpers -------------------------------
" The marks for the last 100 files will be remembered.  We need the history
" feature to remember the current directory name.
set viminfo='100,\"500,h

" Hook the event to the fake file, which might automatically exit vim.
au BufEnter .shellexit.sh :call <sid>ExitVim()

" Exit the current vim if there's no buffer has been modified.
function! s:ExitVim()
	" close the current buffer which is editing the fake file ".shellexit.sh"
	bwipe

	let total=bufnr("$") 
	let i = 1
	while i <= total
		if (getbufvar(i, "&mod"))
			" the current buffer modified, stop quiting
			return
		endif
		let i += 1
	endwhile

	" quit from vim
	qa
endfunction

" ------------------------------ cd helpers -------------------------------
" remap shortcut for suspension key
nnoremap <C-Z> :echo <sid>CopyDirectory() <bar> stop! <CR>

" Copy the current directory name so that the builtin command 'cd' can use it later.
function s:CopyDirectory()
	" netrw already has the directory name in the current buffer
	if (&filetype == "netrw")
		" line 3 is for the directory name
		let directory = substitute(getline(3),  '" *',  '',  '')
	else
		let directory = expand("%:p:h")
	endif

	" Use history as a persistent store to save the current directory name so
	" that we can read it later.  Note debug history doesn't work here.
	let vimbin = "/usr/bin/vim"
	let cmd = "+'call histadd(\"expr\",  \"" . v:servername . " " . shellescape(directory) . "\")"
	call system(vimbin . " -u ~/.vimrc " . cmd . " | quit' -E")
	return directory
endfun

" ------------------------- block cursor utilities -------------------------
" Automatically show or hide the block cursor on various events.
autocmd BufEnter * call ShowBlockCursor()
autocmd BufLeave * call <sid>CleanBlockCursor()
autocmd WinEnter * call ShowBlockCursor()
autocmd WinLeave * call <sid>CleanBlockCursor()

" Function: Momentarily make the current char as a block cursor.
" Parameter: Don't supply any parameter to this function, when the current
" cursor needs to move to a newer position.  Otherwise, just give it an
" arbitrary value.
fun! ShowBlockCursor(...)
	" open the fold if any
	if foldlevel(line(".")) > 0
		exe "normal! zv"
	endif

	" Avoid blank line.
	let display = 0
	if (getline(".") == "")
		let display = 1
		silent keepj let temp = search('\S', 'W')
		if (temp == 0)
			silent keepj let temp = search('\S', 'bW')
		endif
	endif

	hi BlockCursor ctermbg=White ctermfg=Black guibg=White guifg=Black
	let pos = col(".")

	" some tweak for conceal char in help file
	if (&filetype == "help")
		let char = getline('.')[col('.')-1]
		if (char == '*' || char == '|')
			let pos = pos + 1
		endif
	endif

	" we use the time to control the display of block cursor, and this is a
	" hack
	let s:localtime = reltime()
	" exe 'match BlockCursor /\k*\%#\k*/'
	exe 'match BlockCursor /\%' . line(".") . 'l\%' . pos . 'c/'
	if (a:0 == 0 || display == 1)
		autocmd CursorMoved * call <sid>MoveBlockCursor(1)
	else
		autocmd CursorMoved * call <sid>MoveBlockCursor(0)
	endif
	autocmd InsertEnter * match None
endfun

" Function: Make the block cursor disappear.
fun! s:CleanBlockCursor()
	match None
	autocmd! CursorMoved *
endfun

" Function: Use perl to get the current time in milliseconds.
fun! s:Localtime()
	" We're using built-in function reltime, just leave this function here, in
	" case we need it in the future.
	return system("perl -MTime::HiRes -e 'printf(\"%.0f\\n\", Time::HiRes::time()*1000)'")
endfun

" Function: Remove the highlight for the block cursor, only let the highlight
" to appear once.
" Parameter: set it to 1 when we need to show the block cursor again, which
" means the cursor has been just moved by other script, etc.
fun! s:MoveBlockCursor(display)
	" We need to clean up the previous mess.  This can happen when we're
	" staying on the same position.
	call s:CleanBlockCursor()

	" some tweak for conceal char in help file
	let pos = col(".")
	if (&filetype == "help")
		let char = getline('.')[col('.')-1]
		if (char == '*' || char == '|')
			let pos = pos + 1
		endif
		call s:HighlightBlockCursor(pos)

	elseif (&filetype == "netrw")
		" highlight the current char
		call s:HighlightBlockCursor(pos)

	elseif (a:display)
		" When we just enter the window then highligh the block cursor.
		if foldlevel(line(".")) > 0
			exe "normal! zv"
		endif
		call s:HighlightBlockCursor(pos)

	endif

	" no more needed the highlight on second move
	autocmd CursorMoved * call <sid>CleanBlockCursor()
endfun

" Function: Highlight the block cursor when appropriate.
fun! s:HighlightBlockCursor(pos)
	" If the time is too short, we can infer that the cusor movement
	" happened inside vim or the opposite of user input, so we need to
	" highlight the current char as block cursor.
	let temp  = (eval(reltimestr(reltime(s:localtime))))

	" Show the block cursor when the time is less than 100 milliseconds
	if (temp < 0.1)
		exe 'match BlockCursor /\%' . line(".") . 'l\%' . a:pos . 'c/'
	endif
endfun
