#!/usr/bin/env bash
# Requires the following:
# rustup component add llvm-tools-preview
# cargo install cargo-binutils

CRATE=$1

CARGO_ENV=/usr/rust/cargo/env

if [[ -f $CARGO_ENV ]] ; then
  source $CARGO_ENV
  #export PATH=$PATH:/usr/rust/cargo/bin/
fi


if ! [[ -d $CRATE ]] ; then
  echo "Missing crate directory parameter"
  exit 1
fi

export RUSTFLAGS="-Zinstrument-coverage" 
export LLVM_PROFILE_FILE="crate-%m.profraw"

pushd $CRATE
rm -f *.profraw *.profdata
cargo clean
cargo build
cargo test
test_output=$(rustup run nightly cargo test --tests --no-run --message-format=json)
test_files=$(echo "$test_output" | jq -r "select(.profile.test == true) | .filenames[]" | grep -v dSYM)

cargo profdata -- merge -sparse *.profraw -o crate.profdata && \
cargo cov -- report --ignore-filename-regex='/.cargo/registry' --instr-profile=crate.profdata --summary-only \
$(for file in $test_files ; do 
  printf "%s %s " -object $file;
done) >coverage.txt
echo $CRATE
grep TOTAL coverage.txt
rm -f *.profraw *.profdata
popd
