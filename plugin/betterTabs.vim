" Vim plugin to keep buffers separated in tabs they were open in
" File:     betterTabs.vim
" Author:   Adrien Fabre (statox)
" License:  This file is distributed under the MIT License

" Let's not be dictators, users can disable the plugin if they want
if exists("g:loaded_betterTabs")
    finish
endif
let g:loaded_betterTabs = 1

" save cpoptions and restore at the end of the script
let s:save_cpo = &cpo
set cpo&vim

" Dictionary containing all the tabs and their buffers
if !exists("s:BuffersManager") 
    let s:BuffersManager= {}
endif

" List containing the filetype of buffers not to add in the manager
if !exists("s:ignoredFiletypes")
    let s:ignoredFiletypes = ["help", "nerdtree"]
endif

" Show the content of the bufferManager dictionary
function! s:ListBuffers()
    if exists("s:BuffersManager") 
        for tab in keys(s:BuffersManager)

            if tab == tabpagenr()
                let tabStatus = "> Tab "
            else
                let tabStatus = "  Tab "
            endif

            echo tabStatus . tab

            for buf in s:BuffersManager[tab]

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

" Called at vim starting to get the buffers passed as arguments
function! s:StartUpInitialization()
   " Call Add function for every buffers
   let l:nr = 1
   while l:nr <= bufnr('$')
       bufdo call <SID>AddBufferToTab()
       let l:nr += 1
   endwhile
endfunction

" when a new buffer is created append it to the buffer manager
function! s:AddBufferToTab()
    let newBufNr = bufnr("%") 

    " create an entry for the current tab if necessary
    if !has_key(s:BuffersManager, tabpagenr())
        let  s:BuffersManager[tabpagenr()] = []
    endif

    " Get conditions to add the tab
    let isListed            =  buflisted(newBufNr)
    let isAlreadyInManager  =  index(s:BuffersManager[tabpagenr()], newBufNr) != -1
    let isNERDTreeBuffer    =  bufname("%") =~ "NERD_Tree_"
    let isOfIgnoredFT       =  index(s:ignoredFiletypes, &filetype) != -1

    " Add the buffer to the tab
    if isListed && !isAlreadyInManager && !isNERDTreeBuffer && !isOfIgnoredFT
        call add (s:BuffersManager[tabpagenr()],newBufNr)
    endif

    " remove a buffer if it was added whereas it shoudln't
    " (solve the issue with nerdtree buffers which are created and then set as hidden)
    if isAlreadyInManager && (!isListed || isNERDTreeBuffer || isOfIgnoredFT)
        call <SID>RemoveBufferFromTab()
    endif
endfunction

" when a buffer is closed remove it from the buffer manager
function! s:RemoveBufferFromTab()
    let currentTabNr = string(tabpagenr())
    let bufNr = bufnr("%")
    let altBufNr = bufnr("#")

    if has_key(s:BuffersManager, currentTabNr)
        let indexBuf = index(s:BuffersManager[currentTabNr], bufNr)
        if indexBuf != -1
            " update bufferManager
            call remove (s:BuffersManager[currentTabNr], indexBuf)

            " Before deleting the buffer switch to alternate buffer 
            " or close current tab if nothin remains in it
            if len(s:BuffersManager[currentTabNr]) > 0
                execute 'b#'
            else
                execute 'tabclose'
            endif
        endif

        " delete the buffer
        if &filetype != "help"
            execute 'bdelete ' . bufNr
        endif
    else
        echom ("no entry for tab " . currentTabNr)
    endif
endfunction

" switch to next buffer in the tab
function! s:NextBuffer() 
    " find the index of the next buffer for the current tab
    let s = index(s:BuffersManager[tabpagenr()], bufnr("%"))
    if (s != -1)
        let s = (s +1) % len(s:BuffersManager[tabpagenr()])
        execute 'b ' . s:BuffersManager[tabpagenr()][s]
    endif
endfunction

" switch to previous buffer in the tab
function! s:PreviousBuffer() 
    " find the index of the next buffer for the current tab
    let s = index(s:BuffersManager[tabpagenr()], bufnr("%"))
    if (s != -1)
        let s = (s -1) % len(s:BuffersManager[tabpagenr()])
        execute 'b ' . s:BuffersManager[tabpagenr()][s]
    endif
endfunction

" when a tab is closed, close all the buffer it contains
function! s:ClearTab()
    let currentTabNr = string(tabpagenr())
    if has_key(s:BuffersManager, currentTabNr)
        if len(s:BuffersManager[currentTabNr]) > 0
            for buf in s:BuffersManager[currentTabNr]
                execute 'b' . buf
                call <SID>RemoveBufferFromTab()
            endfor
        endif
        call remove(s:BuffersManager, currentTabNr)
    endif
endfunction

" Function allowing to change buffer keeping a consistent
" state of the bufferManager
function! s:ChangeBuffer()
    " output the buffer list to help the user
    call <SID>ListBuffers()

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
    if exists("s:BuffersManager") 
        for tab in keys(s:BuffersManager)
            if index(s:BuffersManager[tab], bufnr(nextBufName)) != -1
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
    autocmd!
    autocmd! BufEnter     * call <SID>AddBufferToTab()
    autocmd! BufEnter     * call <SID>AddBufferToTab()
    autocmd! BufWinEnter  * call <SID>AddBufferToTab()
    autocmd! BufNew       * call <SID>AddBufferToTab()
    autocmd! BufAdd       * call <SID>AddBufferToTab()
    autocmd! BufCreate    * call <SID>AddBufferToTab()

    autocmd! VimEnter     * call <SID>StartUpInitialization()
augroup END


" Create the command which are easier to use than functions
command! NextBuf   call <SID>NextBuffer()
command! PrevBuf   call <SID>PreviousBuffer()
command! ChangeBuf call <SID>ChangeBuffer()
command! ListBuf   call <SID>ListBuffers()
command! CloseBuf  call <SID>RemoveBufferFromTab()
command! CloseTab  call <SID>ClearTab()

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

" restore cpoptions
let &cpo = s:save_cpo
unlet s:save_cpo
