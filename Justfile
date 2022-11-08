alias b := build
alias t := test
alias pr := prove
alias pb := publish

NAMED_ADDRESSES := "MentaLabs=default"

default:
	@just --list -u

build   package=invocation_directory():                 (_aptos-move "compile" package "--save-metadata")
prove   package=invocation_directory(): (build package) (_aptos-move "prove"   package)
publish package=invocation_directory(): (build package) (_aptos-move "publish" package)

test    package=invocation_directory(): (build package)
	aptos move test --package-dir {{package}}

docgen  package=invocation_directory(): (build package)
	-move docgen -p {{package}} -t doc_template/README.md -d -v

watch cmd="build" package=invocation_directory():
	watchexec -ce move just {{cmd}} {{package}}

_aptos-move CMD PACKAGE_DIR EXTRA_FLAGS="":
	aptos move {{CMD}} \
		--package-dir {{PACKAGE_DIR}} \
		--named-addresses {{NAMED_ADDRESSES}} \
		{{EXTRA_FLAGS}}

