# Marks for kakoune
declare-option str marks_file %sh{echo "$HOME/.kak_marks.json"}

declare-option line-specs harp_marks

define-command -hidden highlight_marks %{
  evaluate-commands %sh{
    [ ! -f "$kak_opt_marks_file" ] && { echo "set-option window harp_marks %val{timestamp}"; exit; }

    cwd=$(echo "$(pwd)" | sed "s|^/home/[^/]*|~|")
    specs=$(jq -r --arg section "$cwd/$kak_bufname:mark" --arg filename "$kak_bufname" '
      ((.[$section] // {}) | to_entries[] | select(.value != null and .value != "") | (.value | split(".")[0]) + ":" + .key),
      (to_entries[] | select(.key | endswith(":mark")) | .value | to_entries[] | 
       select(.value != null and .value != "") |
       select(.value | contains($filename + ":")) | 
       (.value | split($filename + ":")[1] | split(".")[0]) + ":" + .key)
    ' "$kak_opt_marks_file" 2>/dev/null | 
    awk -F: '{m[$1]=m[$1]$2} END{for(l in m) print l"|{blue+b}"m[l]}' | 
    sed "s/.*/'&'/" | tr '\n' ' ')

    echo "set-option window harp_marks %val{timestamp} $specs"
  }
}

define-command mark_get -params 1 %{
  evaluate-commands %sh{
    cwd=$(echo "$(pwd)" | sed "s|^/home/[^/]*|~|")
    case "$1" in
      [a-z]) section="$cwd/$kak_bufname:mark";;
      [A-Z]) section="$cwd:mark";;
      *) echo "fail 'Use [a-z] for local or [A-Z] for global marks'"; exit 1 ;;
    esac

    result=$(jq -r ".[\"$section\"][\"$1\"]" $kak_opt_marks_file 2>/dev/null)
    if [ -n "$result" ] && [ "$result" != "null" ]; then
      case "$result" in
        *:*)
          filepath=$(echo "$result" | cut -d':' -f1)
          selection_desc=$(echo "$result" | cut -d':' -f2)
          echo "edit -existing '$filepath'"
          echo "select '$selection_desc'"
          echo "execute-keys vv"
          ;;
        *)
          selection_desc="$result"
          echo "select '$selection_desc'"
          echo "execute-keys vv"
          ;;
      esac
    else
      echo "fail 'Mark not found'"
    fi
  }
}

define-command mark_set -params 1 %{
  evaluate-commands %sh{
    if [ ! -f "$kak_opt_marks_file" ]; then
      mkdir -p "$(dirname "$kak_opt_marks_file")"
      echo '{}' > "$kak_opt_marks_file"
    fi
    
    cwd=$(echo "$(pwd)" | sed "s|^/home/[^/]*|~|")
    case "$1" in
      [a-z]) 
        section="$cwd/$kak_bufname:mark"
        value="$kak_selection_desc"
        ;;
      [A-Z])
        section="$cwd:mark"
        value="$kak_bufname:$kak_selection_desc"
        ;;
      *) 
        echo "fail 'Use [a-z] for local or [A-Z] for global marks'"
        exit 1 
        ;;
    esac
    
    if jq ".[\"$section\"][\"$1\"] = \"$value\"" "$kak_opt_marks_file" > /tmp/temp.json 2>/dev/null; then
      mv /tmp/temp.json "$kak_opt_marks_file"
      echo "echo 'Mark $1 set'"
      echo "highlight_marks"
    else
      echo "fail 'Failed to set mark'"
    fi
  }
}

define-command marks %{
  evaluate-commands -save-regs dquote %sh{
    [ ! -f "$kak_opt_marks_file" ] && { echo "info 'No marks found'"; exit; }
    
    marks=$(jq -r '
      to_entries[] | 
      select(.key | endswith(":mark")) |
      .key as $section | .value | to_entries[] |
      select(.value != null and .value != "") |
      if (.value | contains(":")) then
        .key + " => " + (.value | split(":")[0]) + " => " + (.value | split(":")[1])
      else
        .key + " => " + ($section | sub(":mark$"; "") | sub(".*/"; "")) + " => " + .value
      end
    ' "$kak_opt_marks_file" 2>/dev/null)
    
    if [ -z "$marks" ]; then
      echo "info 'No marks found'"
    else
      echo "info -title 'All Marks' '$marks'"
    fi
  }
}

define-command mark_del -params 1 %{
  evaluate-commands %sh{
    cwd=$(echo "$(pwd)" | sed "s|^/home/[^/]*|~|")
    case "$1" in
      [a-z]) section="$cwd/$kak_bufname:mark";;
      [A-Z]) section="$cwd:mark";;
      *) echo "fail 'Use [a-z] for local or [A-Z] for global marks'"; exit 1 ;;
    esac
    
    # Check if mark exists first
    if ! jq -e --arg s "$section" --arg r "$1" '.[$s][$r]' "$kak_opt_marks_file" >/dev/null 2>&1; then
      echo "fail 'Mark $1 not found'"
      exit 1
    fi
    
    # Delete the mark and clean up empty sections
    if jq --arg s "$section" --arg r "$1" 'del(.[$s][$r]) | if (.[$s] | length) == 0 then del(.[$s]) else . end' "$kak_opt_marks_file" > /tmp/temp.json 2>/dev/null; then
      mv /tmp/temp.json "$kak_opt_marks_file"
      echo "echo 'Mark $1 deleted'"
      echo "highlight_marks"
    else
      echo "fail 'Failed to delete mark'"
    fi
  }
}

hook -always global ModeChange '\Qpush:normal:next-key[user.marks_goto]\E' %{
  set-option window autoinfo ''
  hook -always -once window ModeChange '\Qpop:next-key[user.marks_goto]:normal\E' %{
    unset-option window autoinfo
  }
}

hook -always global ModeChange '\Qpush:normal:next-key[user.marks_add]\E' %{
  set-option window autoinfo ''
  hook -always -once window ModeChange '\Qpop:next-key[user.marks_add]:normal\E' %{
    unset-option window autoinfo
  }
}

hook -always global ModeChange '\Qpush:normal:next-key[user.marks_del]\E' %{
  set-option window autoinfo ''
  hook -always -once window ModeChange '\Qpop:next-key[user.marks_del]:normal\E' %{
    unset-option window autoinfo
  }
}

declare-user-mode marks_goto
evaluate-commands %sh{
  for c in {a..z} {A..Z}; do
    printf "map -docstring 'Go to Mark %s' global marks_goto %s ':mark_get %s<ret>'\n" "$c" "$c" "$c" 
  done
}

declare-user-mode marks_add
evaluate-commands %sh{
  for c in {a..z} {A..Z}; do
    printf "map -docstring 'Add Mark %s' global marks_add %s ':mark_set %s<ret>'\n" "$c" "$c" "$c" 
  done
}

declare-user-mode marks_del
evaluate-commands %sh{
  for c in {a..z} {A..Z}; do
    printf "map -docstring 'Del Mark %s' global marks_del %s ':mark_del %s<ret>'\n" "$c" "$c" "$c" 
  done
}

hook global WinDisplay '.*' %{
  highlight_marks
  add-highlighter -override window/harp_marks flag-lines default harp_marks
}

declare-user-mode marks
map global normal "'" ':enter-user-mode marks<ret>' -docstring 'Marks'
map global marks g ':enter-user-mode marks_goto<ret>' -docstring 'Marks Goto'
map global marks a ':enter-user-mode marks_add<ret>' -docstring 'Marks Add'
map global marks d ':enter-user-mode marks_del<ret>' -docstring 'Marks Delete'
