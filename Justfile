alias b := build
alias t := test
alias pr := prove
alias pb := publish

named_addresses := "MentaLabs=default"

default:
	@just --choose

build package=".": (_aptos-move "compile" package)
test package=".": (_aptos-move "test" package)
prove package=".": (_aptos-move "prove" package)
publish package=".": (_aptos-move "publish" package)

_aptos-move CMD PACKAGE_DIR:
	aptos move {{CMD}} \
		--package-dir {{PACKAGE_DIR}} \
		--named-addresses {{named_addresses}}

