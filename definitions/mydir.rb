define :mydir, mode: "755", group: nil do
  dirpath = params[:name]
  group_ = params[:group] || node[:group]

  directory dirpath do
    owner user
    group group_
    mode params[:mode]
  end
end
