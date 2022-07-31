# snapup.sh

Perform backups using ZFS snapshots

## Preconditions
I wrote the script within a few minutes and it probably needs much more love.

I use FreeBSD on my clients almost everywhere and OmniOS (illumos) on my backup server. That's why "pfexec" appears in the script.
The script expects a receiver configured with publickey, which is illumos based and whose user has administrator permissions.

The latter can probably be replaced by doas or sudo if the other side is Linux or BSD based.
Of course, access must then be given via nopasswd. Alternatively, you can also give the user appropriate permissions on the zpool.

## Caution
Use at your own risk, I don't see this as quite stable yet. Be careful that it does not eat your zpool.
