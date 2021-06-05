" Ensure vim-plug installed
let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

" Specify plugin directory
call plug#begin('~/.vim/plugs')

" Git integration with Vim
Plug 'airblade/vim-gitgutter'

" vim-go
Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }

" Sidebar file navigation in vim
Plug 'preservim/nerdtree'

" Completion framework and language server client
Plug 'neoclide/coc.nvim', { 'branch': 'release' }

" YAML
Plug 'neoclide/coc-yaml'

"Vim status bar
Plug 'vim-airline/vim-airline'

" Initialize plugin system
call plug#end()



" NOTE: Comments in Vim are denoted with a double quote.
set background=dark
set number " Show line numbers
set hlsearch " Highlight search
highlight lineNr ctermfg=white " Make line numbers white
set autoindent

" Tab size = 4
set tabstop=4
set shiftwidth=4
set expandtab

set updatetime=100

" Make backspace more intuitive
set backspace=indent,eol,start

" Enable mouse clicking
set mouse=a

" Invoke goimports on save
let g:go_fmt_command="goimports"

" Show hidden files in NERDTRee
let NERDTreeShowHidden=1

" Ignore coc warnings
let g:coc_disable_startup_warning = 1

" Make gitgutter column clear
highlight clear SignColumn

set encoding=utf-8
