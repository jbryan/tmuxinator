#!<%= ENV['SHELL'] || '/bin/bash' %>
# pre needs to be run before starting the server so 
# if it exports environment variables, they get picked
# up by the tmux server

tmux <%= socket %> start-server

if ! $(tmux <%= socket %> has-session -t <%=s @project_name %>); then
cd <%= @project_root || "." %>
<%= @pre.kind_of?(Array) ? @pre.join(" && ") : @pre %>
env <%= environment.collect{ |k,v| "#{k}=\"#{v}\"" }.join(" ") %> TMUX= tmux <%= socket %> start-server \; new-session -d -s <%=s @project_name %> -n <%=s @tabs[0].name %>
tmux <%= socket %> set-option -t <%=s @project_name %> default-path <%= @project_root %>

<% settings.each do |setting| %>
tmux <%= socket %> set-option -t <%=s @project_name%> <%= setting %>
<% end %>

<% environment.each do |key, value| %>
tmux <%= socket %> set-environment -t <%=s @project_name%> <%= key %> "<%= value %>"
<% end %>

<% hotkeys.each do |hotkey| %>
tmux <%= socket %> bind-key <%= hotkey %>
<% end %>

<% @tabs[1..-1].each_with_index do |tab, i| %>
tmux <%= socket %> new-window -t <%= window(i+2) %> -n <%=s tab.name %>
<% end %>

# set up tabs and panes
<% @tabs.each_with_index do |tab, i| %>
# tab "<%= tab.name %>"
<%   if tab.command %>
<%=    send_keys(tab.command, i+1) %>
<%   elsif tab.panes %>
<%=    send_keys(tab.panes.shift, i+1) %>
<%     tab.panes.each do |pane| %>
tmux <%= socket %> splitw -t <%= window(i+1) %>
<%=      send_keys(pane, i+1) %>
<%     end %>
tmux <%= socket %> select-layout -t <%= window(i+1) %> <%=s tab.layout %>
tmux <%= socket %> select-pane -t <%= window(i+1) %>.0
<%   end %>
<% end %>

tmux <%= socket %> select-window -t <%= window(1) %>

fi

if [ -z $TMUX ]; then
    tmux <%= cli_args %> <%= socket %> -u attach-session -t <%=s @project_name %>
else
    tmux <%= socket %> -u switch-client -t <%=s @project_name %>
fi
