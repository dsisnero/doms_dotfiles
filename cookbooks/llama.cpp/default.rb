include_cookbook "ghq"

home = node[:home]
user = node[:user]
repos = node[:repos]

case node[:platform]
when "darwin"
  package "cmake"
  package "python@3.11"

  get_repo "ggml-org/llama.cpp"

  cloned_dir = "#{repos}/github.com/ggml-org/llama.cpp"
  build_dir = "#{cloned_dir}/build"
  local_bin = "#{home}/.local/bin"

  mydir local_bin

  file "#{cloned_dir}/build.sh" do
    mode "755"
    user user
    content <<~EOS
      #!/bin/bash
      set -eu

      find . -name '._*' -delete

      cmake -B build \
        -DCMAKE_BUILD_TYPE=Release \
        -DGGML_METAL=ON \
        -DGGML_ACCELERATE=ON \
        -DGGML_BLAS=ON \
        -DGGML_BLAS_VENDOR=Apple

      cmake --build build --config Release -j

      mkdir -p #{local_bin}
      for f in build/bin/*; do
        ln -sf "$PWD/$f" #{local_bin}/
      done
    EOS
  end
end
