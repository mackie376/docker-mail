# docker-neovim

Neomutt in Docker container.

## usage

```sh
# create directory for account information
mkdir ~/.mail-account

# create config.json into above directory
# (see config.json.sample)
:> ~/.mail-account/config.json

# create mail data volume
docker volume create -d local -name mail-data

# run
docker run -it --rm -v mail-data:/home/mackie/.maildir -v ${HOME}/.mail-account:/home/mackie/.account -v ${HOME}/Downloads:/home/mackie/Downloads mackie376/mail:x.x.x
```
