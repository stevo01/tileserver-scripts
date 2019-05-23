stub:
	@/bin/echo -e 'There is nothing to "make" here, type \033[1mmake install\033[0m to install scripts'
install:
	install -g root -o root -m 755 whichdiff.pl replicate-loop.sh expirehrb expiremeta.pl /usr/local/bin
	cp osm-replicate.service osm-replicate.timer /etc/systemd/system
	@/bin/echo ""
	@/bin/echo -e "Run \033[1msystemctl enable osm-replicate.timer\033[0m to activate update script!"
