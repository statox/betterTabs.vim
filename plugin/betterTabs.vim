" File: betterTabs.vim
" Author: Adrien Fabre (statox)

" Dictionary containing all the tabs and their buffers
if !exists("g:BuffersManager") 
    let g:BuffersManager= {}
endif

" Helper function for development purpose
" Show the content of the bufferManager dictionary
function! ListBuffers()
    if exists("g:BuffersManager") 
        for tab in keys(g:BuffersManager)

            if tab == tabpagenr()
                let tabStatus = "> Tab "
            else
                let tabStatus = "  Tab "
            endif

            echo tabStatus . tab

            for buf in g:BuffersManager[tab]

                if buf == string(bufnr("%"))
                    let bufStatus = " %"
                elseif buf == string(bufnr("#"))
                    let bufStatus = " #"
                else
                    let bufStatus = "  "
                endif

                if bufname(buf) == ""
                    let bufName = "\"[No name]\""
                else
                    let bufName = " \"" . bufname(buf) . "\""
                endif


                echo "  " . buf . bufStatus . "\t"  bufName
            endfor
            echo "\n"
        endfor
    endif
endfunction

" when a new buffer is created append it to the buffer manager
function! AddBufferToTab()
    let newBufNr = bufnr("%") 

    if !has_key(g:BuffersManager, tabpagenr())
        let  g:BuffersManager[tabpagenr()] = []
    endif

    " Add the buffer to the tab
    if index(g:BuffersManager[tabpagenr()], newBufNr) == -1 && buflisted(newBufNr)
        call add (g:BuffersManager[tabpagenr()],newBufNr)
    endif
endfunction

" when a buffer is closed remove it from the buffer manager
function! RemoveBufferFromTab()
    let currentTabNr = string(tabpagenr())
    let bufNr = bufnr("%")
    let altBufNr = bufnr("#")

    if has_key(g:BuffersManager, currentTabNr)
        let indexBuf = index(g:BuffersManager[currentTabNr], bufNr)
        if indexBuf != -1
            " update bufferManager
            call remove (g:BuffersManager[currentTabNr], indexBuf)

            " Before deleting the buffer switch to alternate buffer 
            " or close current tab if nothin remains in it
            if len(g:BuffersManager[currentTabNr]) > 0
                execute 'b#'
            else
                execute 'tabclose'
            endif

            " delete the buffer
            execute 'bdelete ' . bufNr
        else
            "echom ("no buffer " . bufNr . " in tab " . currentTabNr)
            " delete the buffer
            execute 'bdelete ' . bufNr
        endif
    else
        echom ("no entry for tab " . currentTabNr)
    endif
endfunction

" switch to next buffer in the tab
function! NextBuffer() 
    " find the index of the next buffer for the current tab
    let s = index(g:BuffersManager[tabpagenr()], bufnr("%"))
    if (s != -1)
        let s = (s +1) % len(g:BuffersManager[tabpagenr()])
        execute 'b ' . g:BuffersManager[tabpagenr()][s]
    endif
endfunction

" switch to previous buffer in the tab
function! PreviousBuffer() 
    " find the index of the next buffer for the current tab
    let s = index(g:BuffersManager[tabpagenr()], bufnr("%"))
    if (s != -1)
        let s = (s -1) % len(g:BuffersManager[tabpagenr()])
        execute 'b ' . g:BuffersManager[tabpagenr()][s]
    endif
endfunction

" when a tab is closed, close all the buffer it contains
function! ClearTab()
    let currentTabNr = string(tabpagenr())
    if has_key(g:BuffersManager, currentTabNr)
        if len(g:BuffersManager[currentTabNr]) > 0
            for buf in g:BuffersManager[currentTabNr]
                execute 'b' . buf
                call RemoveBufferFromTab()
            endfor
        endif
        call remove(g:BuffersManager, currentTabNr)
    endif
endfunction

" Function allowing to change buffer keeping a consistent
" state of the bufferManager
function! ChangeBuffer()
    " output the buffer list to help the user
    call ListBuffers()

    " get user input
    let nextBuf = input("Buffer: ", "", "buffer")

    " if the user inputs a buffer number we get the buffer name
    " else the user had input a buffer name
    if str2nr(nextBuf) != ""
        let nextBufName = bufname(str2nr(nextBuf))
    else
        let nextBufName = nextBuf
    endif

    " looking for the buffer in the BufferManager
    if exists("g:BuffersManager") 
        for tab in keys(g:BuffersManager)
            if index(g:BuffersManager[tab], bufnr(nextBufName)) != -1
                " change to the tab containing the buffer
                while string(tabpagenr()) != tab
                    execute "tabn"
                endwhile
                " change to the buffer
                execute "b " . nextBufName
            endif
        endfor
    endif
endfunction

" autocommands to trigger the bufferManager actions
augroup BuffersManagerGroup
    autocmd! BufEnter * call AddBufferToTab()
    autocmd! BufWinEnter * call AddBufferToTab()
    autocmd! WinEnter * call AddBufferToTab()
    "autocmd! BufWipeout * call RemoveBufferFromTab()
    "autocmd! BufDelete  * call RemoveBufferFromTab()
augroup END


" Create the command which are easier to use than functions
command! NextBuf   call NextBuffer()
command! PrevBuf   call PreviousBuffer()
command! ChangeBuf call ChangeBuffer()
command! ListBuf   call ListBuffers()
command! CloseBuf  call RemoveBufferFromTab()
command! CloseTab  call ClearTab()

" Let the users override the default mapping if they want
if !exists('g:betterTabsVim_map_keys')
    let g:betterTabsVim_map_keys = 1
endif

" create the mappings of the plugin
if g:betterTabsVim_map_keys
    " change of buffer in the current tab
    nnoremap <Leader>h :PrevBuf<CR>
    nnoremap <Leader>l :NextBuf<CR>

    " change of buffer in any tab
    nnoremap <Leader>bb :ChangeBuf<CR>

    " list buffers
    nnoremap <F2> :ListBuf<CR>

    " delete a buffer
    nnoremap <Leader>bc :CloseBuf<CR>

    " close a tab and the buffers it contains
    nnoremap <Leader>tc :CloseTab<CR>
endif
