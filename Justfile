alias b := build
alias t := test
alias pr := prove
alias pb := publish

NAMED_ADDRESSES := "MentaLabs=default"

default:
	@just --list -u

build   package=invocation_directory():								  (_aptos-move "compile" package)
test    package=invocation_directory(): (build package) (_aptos-move "test"		 package)
prove   package=invocation_directory(): (build package) (_aptos-move "prove"	 package)
publish package=invocation_directory(): (build package) (_aptos-move "publish" package)

_aptos-move CMD PACKAGE_DIR:
	aptos move {{CMD}} \
		--package-dir {{PACKAGE_DIR}} \
		--named-addresses {{NAMED_ADDRESSES}}

