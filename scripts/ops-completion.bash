#!/usr/bin/env bash
# Bash completion for ops.sh

_ops_units() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  local units=()
  
  # Get all units from ORDER array in ops.sh
  # This is a simplified version - in practice, you'd source ops.sh to get ORDER
  local srv_dir="${OPS_ROOT:-$(pwd)}/srv"
  
  if [[ -d "$srv_dir" ]]; then
    while IFS= read -r -d '' dir; do
      local rel_path="${dir#$srv_dir/}"
      if [[ "$rel_path" == */* ]]; then
        units+=("$rel_path")
        # Also add just the name part
        local name="${rel_path##*/}"
        units+=("$name")
      fi
    done < <(find "$srv_dir" -mindepth 2 -maxdepth 2 -type d -print0 2>/dev/null)
  fi
  
  # Add "all" as an option
  units+=("all")
  
  COMPREPLY=($(compgen -W "${units[*]}" -- "$cur"))
}

_ops_commands() {
  local commands=("bootstrap" "preflight" "up" "down" "restart" "validate" "status" "logs")
  local cur="${COMP_WORDS[COMP_CWORD]}"
  COMPREPLY=($(compgen -W "${commands[*]}" -- "$cur"))
}

_ops() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  local prev="${COMP_WORDS[COMP_CWORD-1]}"
  
  case "$prev" in
    up|down|restart|validate|status|logs)
      _ops_units
      ;;
    logs)
      # For logs, first complete unit, then service name
      if [[ ${COMP_CWORD} -eq 2 ]]; then
        _ops_units
      else
        # Service name completion would go here
        COMPREPLY=()
      fi
      ;;
    *)
      if [[ ${COMP_CWORD} -eq 1 ]]; then
        _ops_commands
      else
        COMPREPLY=()
      fi
      ;;
  esac
}

complete -F _ops ops.sh
complete -F _ops ./ops.sh

