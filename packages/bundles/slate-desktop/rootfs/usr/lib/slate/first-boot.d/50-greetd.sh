# Install Slate's greeter configuration.
#
# The greetd package owns /etc/greetd/config.toml, so slate-desktop cannot ship
# that path directly — two owners of one path is a file conflict that fails
# pacstrap. The packaged copy is installed here instead, and only if it has not
# already been customised.
if [[ -f /usr/share/slate/greetd/config.toml ]]; then
    install -Dm644 /usr/share/slate/greetd/config.toml /etc/greetd/config.toml
    log "installed Slate's greetd configuration"
fi
