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
    if !has_key(g:BuffersManager, tabpagenr())
        let  g:BuffersManager[tabpagenr()] = []
    endif

    " Add the buffer to the tab
    if index(g:BuffersManager[tabpagenr()], bufnr("%")) == -1 && bufnr("%") != "" && bufname("%") != "" && buflisted("%") != 0
        call add (g:BuffersManager[tabpagenr()],bufnr("%"))
    endif
endfunction

" when a buffer is closed remove it from the buffer manager
function! RemoveBufferFromTab()
    echom "Removing buffer"
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
            echom ("no buffer " . bufNr . " in tab " . currentTabNr)
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

" autocommands to trigger the bufferManager actions
augroup BuffersManagerGroup
    autocmd! BufEnter * call AddBufferToTab()
    "autocmd! BufWipeout * call RemoveBufferFromTab()
    "autocmd! BufDelete  * call RemoveBufferFromTab()
augroup END


" Let the users override the default mapping if they want
if !exists('g:betterTabsVim_map_keys')
    let g:betterTabsVim_map_keys = 1
endif

" create the mappings of the plugin
if g:betterTabsVim_map_keys
    nnoremap <Leader>h <Esc>:call PreviousBuffer()<CR>
    vnoremap <Leader>h <Esc>:call PreviousBuffer()<CR>
    
    nnoremap <Leader>l <Esc>:call NextBuffer()<CR>
    vnoremap <Leader>l <Esc>:call NextBuffer()<CR>

    nnoremap <F2> :call ListBuffers()<CR>

    nnoremap <Leader>bc :call RemoveBufferFromTab()<CR>
endif
