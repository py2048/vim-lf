if exists('g:loaded_lf_autoload')
  finish
endif
let g:loaded_lf_autoload = 1

function! lf#LF(path, edit_cmd, user_args)
  " Save the edit cmd in a script variable to make it accessible in the callback
  let s:edit_cmd = a:edit_cmd
  " To revert back guioptions after changing them for Vim
  let oldguioptions = &guioptions
  " To temporarily save what files were chosen by lf
  let s:choice_file_path = tempname()

  let s:lf_cmd = ['lf', '-selection-path=' . s:choice_file_path,]
                \ + a:user_args
                \ + [fnameescape(expand(a:path))]

  " To be passed down to termopen
  let termopen_opts = { }
  function! termopen_opts.on_exit(job_id, code, event)
    if filereadable(s:choice_file_path)
      for f in readfile(s:choice_file_path)
        exec s:edit_cmd . f
      endfor
      call delete(s:choice_file_path)
    endif
    if a:code == 0
      " Iterate open buffers and search for our terminal buffer - to delete
      " it afterwards
      for buf in getbufinfo()
        if has_key(buf.variables, 'terminal_job_id') && buf.variables.terminal_job_id == a:job_id
          let bufnr = buf.bufnr
          break
        endif
      endfor
      call execute('BufferClose! ' . bufnr)
    endif
  endfunction
  enew
  " We want Lf to quit after it saves the selections
  call termopen(s:lf_cmd, termopen_opts)
  startinsert
  let &guioptions=oldguioptions
endfunction
