" ╔══════════════════════════════════════════════════════════════╗
" ║               Vim Config                                    ║
" ╚══════════════════════════════════════════════════════════════╝

" ── General ──────────────────────────────────────────────────
set nocompatible              " Use Vim defaults
set encoding=utf-8            " UTF-8 encoding
set fileencoding=utf-8
set history=1000              " Command history
set undolevels=1000           " Undo levels
set undofile                  " Persistent undo
set undodir=~/.vim/undodir
set noswapfile                " No swap files
set nobackup                  " No backup files
set autoread                  " Reload files changed outside vim
set hidden                    " Switch buffers without saving
set clipboard=unnamed         " Use system clipboard
set mouse=a                   " Enable mouse
set backspace=indent,eol,start  " Backspace over everything
set timeoutlen=500            " Faster key sequences
set updatetime=250            " Faster completion

" ── UI ───────────────────────────────────────────────────────
set number                    " Line numbers
set cursorline                " Highlight current line
set showmatch                 " Show matching brackets
set matchtime=2               " Bracket highlight time (0.2s)
set signcolumn=yes            " Always show sign column
set laststatus=2              " Always show status line
set showcmd                   " Show partial commands
set showmode                  " Show current mode
set ruler                     " Show cursor position
set wildmenu                  " Enhanced command completion
set wildmode=longest:list,full
set title                     " Set terminal title
set termguicolors             " True color support
syntax enable                 " Syntax highlighting

" ── Search ───────────────────────────────────────────────────
set hlsearch                  " Highlight search results
set incsearch                 " Incremental search
set ignorecase                " Case insensitive search
set smartcase                 " Case sensitive if uppercase used
" Clear search highlight with Esc
nnoremap <Esc> :nohlsearch<CR>

" ── Indentation ──────────────────────────────────────────────
set autoindent                " Auto indent
set smartindent               " Smart indent
set expandtab                 " Spaces instead of tabs
set tabstop=2                 " Tab width
set shiftwidth=2              " Indent width
set softtabstop=2             " Soft tab width
set shiftround                " Round indent to shiftwidth
filetype plugin indent on     " Filetype-specific indentation

" ── Filetype-specific ────────────────────────────────────────
autocmd FileType python setlocal tabstop=4 shiftwidth=4 softtabstop=4
autocmd FileType go setlocal tabstop=4 shiftwidth=4 softtabstop=4 noexpandtab
autocmd FileType make setlocal noexpandtab
autocmd FileType yaml setlocal tabstop=2 shiftwidth=2
autocmd FileType terraform setlocal tabstop=2 shiftwidth=2
autocmd FileType json setlocal tabstop=2 shiftwidth=2
autocmd FileType dockerfile setlocal tabstop=4 shiftwidth=4

" ── Splits ───────────────────────────────────────────────────
set splitbelow                " Horizontal splits below
set splitright                " Vertical splits right
" Navigate splits with Ctrl+hjkl
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" ── Leader Key ───────────────────────────────────────────────
let mapleader = " "           " Space as leader

" File operations
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>
nnoremap <leader>x :x<CR>

" Buffer navigation
nnoremap <leader>bn :bnext<CR>
nnoremap <leader>bp :bprevious<CR>
nnoremap <leader>bd :bdelete<CR>
nnoremap <leader>bl :ls<CR>

" Tab navigation
nnoremap <leader>tn :tabnext<CR>
nnoremap <leader>tp :tabprevious<CR>
nnoremap <leader>tc :tabnew<CR>

" Quick edit/source vimrc
nnoremap <leader>ev :edit $MYVIMRC<CR>
nnoremap <leader>sv :source $MYVIMRC<CR>

" ── Quality of Life ──────────────────────────────────────────
" Move lines up/down in visual mode
vnoremap J :m '>+1<CR>gv=gv
vnoremap K :m '<-2<CR>gv=gv

" Keep cursor centered when scrolling
nnoremap <C-d> <C-d>zz
nnoremap <C-u> <C-u>zz
nnoremap n nzzzv
nnoremap G Gzz

" Don't lose selection when indenting
vnoremap < <gv
vnoremap > >gv

" Y yanks to end of line (consistent with D and C)
nnoremap Y y$

" Quick save
nnoremap <C-s> :w<CR>
inoremap <C-s> <Esc>:w<CR>a

" ── Status Line ──────────────────────────────────────────────
set statusline=
set statusline+=\ %{toupper(mode())}     " Mode
set statusline+=\ \|\ %f                  " File path
set statusline+=\ %m%r                    " Modified/readonly
set statusline+=%=                        " Right align
set statusline+=\ %{&filetype}            " Filetype
set statusline+=\ \|\ %{&fileencoding}    " Encoding
set statusline+=\ \|\ L%l/%L\ C%c        " Line/Col
set statusline+=\

" ── Netrw (built-in file explorer) ──────────────────────────
let g:netrw_banner = 0        " Hide banner
let g:netrw_liststyle = 3     " Tree view
let g:netrw_browse_split = 4  " Open in previous window
let g:netrw_altv = 1          " Open splits to the right
let g:netrw_winsize = 25      " Width 25%
nnoremap <leader>e :Lexplore<CR>

" ── Trailing Whitespace ─────────────────────────────────────
highlight TrailingWhitespace ctermbg=red guibg=red
match TrailingWhitespace /\s\+$/
" Strip trailing whitespace on save
autocmd BufWritePre * :%s/\s\+$//e

" ── Auto-create directories on save ─────────────────────────
autocmd BufWritePre * call mkdir(expand("<afile>:p:h"), "p")

" ── Create undo directory ───────────────────────────────────
if !isdirectory(expand("~/.vim/undodir"))
    call mkdir(expand("~/.vim/undodir"), "p")
endif

" ── Dracula-inspired colors (no plugin needed) ──────────────
set background=dark
highlight Normal       ctermfg=253 ctermbg=NONE
highlight CursorLine   cterm=NONE ctermbg=236
highlight LineNr       ctermfg=239
highlight CursorLineNr ctermfg=215
highlight ColorColumn  ctermbg=235
highlight Visual       ctermbg=240
highlight StatusLine   ctermfg=253 ctermbg=236
highlight Search       ctermfg=0 ctermbg=215
highlight IncSearch    ctermfg=0 ctermbg=117
highlight Pmenu        ctermfg=253 ctermbg=236
highlight PmenuSel     ctermfg=0 ctermbg=117
highlight Comment      ctermfg=103
highlight String       ctermfg=228
highlight Function     ctermfg=117
highlight Keyword      ctermfg=212
highlight Type         ctermfg=117
highlight Constant     ctermfg=141
highlight SignColumn   ctermbg=NONE
