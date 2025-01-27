CHRUBY_VERSION="0.3.9"
RUBIES=()

for dir in "$PREFIX/opt/rubies" "$HOME/.rubies"; do
	[[ -d "$dir" && -n "$(command ls -A "$dir")" ]] && RUBIES+=("$dir"/*)
done
unset dir

function chruby_reset()
{
	[[ -z "$RUBY_ROOT" ]] && return

  local user_dir="$($RUBY_ROOT/bin/ruby -e 'puts Gem.user_dir')"
	PATH=":$PATH:"; PATH="${PATH//:$user_dir\/bin:$RUBY_ROOT\/bin:/:}"

	PATH="${PATH#:}"; PATH="${PATH%:}"
	unset RUBY_ROOT RUBY_ENGINE RUBY_VERSION RUBYOPT
	hash -r
}

function chruby_use()
{
	if [[ ! -x "$1/bin/ruby" ]]; then
		echo "chruby: $1/bin/ruby not executable" >&2
		return 1
	fi

	[[ -n "$RUBY_ROOT" ]] && chruby_reset

	export RUBY_ROOT="$1"
	export RUBYOPT="$2"
  local user_dir="$($RUBY_ROOT/bin/ruby -e 'puts Gem.user_dir')"
  export PATH="$user_dir/bin:$RUBY_ROOT/bin:$PATH"

  export RUBY_VERSION="$($RUBY_ROOT/bin/ruby -e 'puts RUBY_VERSION')"

	hash -r
}

function chruby()
{
	case "$1" in
		-h|--help)
			echo "usage: chruby [RUBY|VERSION|system] [RUBYOPT...]"
			;;
		-V|--version)
			echo "chruby: $CHRUBY_VERSION"
			;;
		"")
			local dir ruby
			for dir in "${RUBIES[@]}"; do
				dir="${dir%%/}"; ruby="${dir##*/}"
				if [[ "$dir" == "$RUBY_ROOT" ]]; then
					echo " * ${ruby} ${RUBYOPT}"
				else
					echo "   ${ruby}"
				fi

			done
			;;
		system) chruby_reset ;;
		*)
			local dir ruby match
			for dir in "${RUBIES[@]}"; do
				dir="${dir%%/}"; ruby="${dir##*/}"
				case "$ruby" in
					"$1")	match="$dir" && break ;;
					*"$1"*)	match="$dir" ;;
				esac
			done

			if [[ -z "$match" ]]; then
				echo "chruby: unknown Ruby: $1" >&2
				return 1
			fi

			shift
			chruby_use "$match" "$*"
			;;
	esac
}
