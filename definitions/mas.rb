define :mas, id: nil, user: nil, not_if_: nil, not_if: nil, only_if_: nil, only_if: nil do
  name_ = params[:name]
  id = params[:id]
  user_ = params[:user] || node[:user]
  not_if_guard = params[:not_if] || params[:not_if_]
  only_if_guard = params[:only_if] || params[:only_if_]
  debug_flag = MItamae.logger.debug? ? '--debug' : ''

  execute "install #{name_}" do
    user user_ unless user_.nil?
    not_if not_if_guard unless not_if_guard.nil?
    only_if only_if_guard unless only_if_guard.nil?
    command <<EOCMD
       mas install #{debug_flag} #{id}
EOCMD
  end
end
