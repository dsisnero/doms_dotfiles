# Rust utility function to compile and run a Rust program in one step
# Usage: rust_run [filename.rs]
function rust_run() {
    # Compile the Rust source file
    rustc $1
    # Extract the binary name by removing the .rs extension
    local binary=$(basename $1 .rs)
    # Execute the compiled binary
    ./$binary
}
