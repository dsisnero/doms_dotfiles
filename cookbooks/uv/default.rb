execute "curl -LsSf https://astral.sh/uv/install.sh | sh" do
  user node[:user]
  not_if "which uv"
end
