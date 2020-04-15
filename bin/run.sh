#!/usr/bin/env ash

_main() (
  local _account_dir="${HOME}/.account"
  local _mairdir=~/.maildir
  local _neomutt_config_dir="${HOME}/.config/neomutt"
  local _neomutt_cache_dir="${HOME}/.cache/neomutt"

  local _account_json="${_account_dir}/config.json"

  if [[ ! -s "$_account_json" ]]; then
    echo "No 'config.json' in ${_account_dir}"
    exit 1
  fi

  _on_create_mbsyncrc() {
    local _config_file="${HOME}/.mbsyncrc"

    if [[ ! -e "$_config_file" ]]; then
      :> "$_config_file"
      chmod 600 "$_config_file"
    fi

    [[ -s "$_config_file" ]] && echo '' >> "$_config_file"
    envsubst < /tmp/mbsyncrc.tmpl >> "$_config_file"
  }

  _on_create_msmtprc() {
    local _config_file="${HOME}/.msmtprc"

    if [[ ! -e "$_config_file" ]]; then
      :> "$_config_file"
      chmod 600 "$_config_file"
    fi

    [[ -s "$_config_file" ]] && echo '' >> "$_config_file"
    envsubst < /tmp/msmtprc.tmpl >> "$_config_file"
  }

  _on_create_neomutt_config() {
    local _config_file="${_neomutt_config_dir}/neomuttrc"
    local _account_config_file="${_neomutt_config_dir}/${_NAME}/config"

    echo '' >> "$_config_file"
    echo "mailboxes '=${_NAME}'" >> "$_config_file"
    echo "mailboxes '=${_NAME}/Inbox'" >> "$_config_file"
    echo "mailboxes '=${_NAME}/Action'" >> "$_config_file"
    echo "mailboxes '=${_NAME}/Hold'" >> "$_config_file"
    echo "mailboxes '=${_NAME}/Archive'" >> "$_config_file"
    echo "mailboxes '=${_NAME}/Starred'" >> "$_config_file"
    echo "mailboxes '=${_NAME}/Trash'" >> "$_config_file"
    echo "mailboxes '=${_NAME}/Sent'" >> "$_config_file"
    echo "mailboxes '=${_NAME}/Drafts'" >> "$_config_file"
    echo "folder-hook ${_NAME}/* source ${_account_config_file}" >> "$_config_file"

    if [[ "$_PRIMARY" == "1" ]]; then
      echo '' >> "$_config_file"
      echo "source $_account_config_file" >> "$_config_file"
    fi

    local _sig_file=$(eval "echo $_SIGNATURE_FILE")
    if [[ -s "$_sig_file" ]]; then
      export _SIGNATURE="set signature=\"${_sig_file}\""
    else
      export _SIGNATURE=''
    fi

    envsubst < /tmp/neomuttrc-account.tmpl > "$_account_config_file"
  }

  _on_load_account() {
    mkdir -p "${_mairdir}/${_NAME}" "${_neomutt_config_dir}/${_NAME}"

    if [[ $_PRIMARY == "1" ]]; then
      export _PRIMARY_ADDR="$_ADDR"
    else
      export _SECONDARY_ADDR="${_SECONDARY_ADDR}${_ADDR};"
    fi

    _on_create_mbsyncrc
    _on_create_msmtprc
    _on_create_neomutt_config
  }

  _on_loaded_account() {
    envsubst < /tmp/notmuchrc.tmpl > ~/.notmuch-config
    chmod 600 ~/.notmuch-config
  }

  _load_account_info() {
    local _json=$(cat "$_account_json")
    local _num_of_account=$(echo $_json | jq length)

    for i in $(seq 0 $((_num_of_account - 1))); do
      local _account=$(echo $_json | jq .[$i])
      export _REALNAME=$(echo $_account | jq -r .realname)
      export _NAME=$(echo $_account | jq -r .name)
      export _PRIMARY=$(echo $_account | jq -r .primary)
      export _USER=$(echo $_account | jq -r .user)
      export _IMAP=$(echo $_account | jq -r .imap)
      export _SMTP=$(echo $_account | jq -r .smtp)
      export _ADDR=$(echo $_account | jq -r .address)
      export _PASSWORD=$(echo $_account | jq -r .password)
      export _SIGNATURE_FILE=$(echo $_account | jq -r .signature)

      _on_load_account
    done

    _on_loaded_account
  }

  _create_directories() {
    mkdir -p "$_neomutt_config_dir" "$_neomutt_cache_dir" "$_mairdir"

    local _whoami=$(whoami)
    chown "${_whoami}:${_whoami}" "$_mairdir"
  }

  _create_directories
  _load_account_info
  neomutt
)

_main "$@"
