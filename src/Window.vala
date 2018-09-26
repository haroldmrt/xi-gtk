// Copyright 2017-2018 Elias Aebi
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

namespace Xi {

[GtkTemplate (ui = "/com/github/eyelash/xi-gtk/gtk/app.ui")]
class Window: Gtk.ApplicationWindow {
	private CoreConnection core_connection;
	private Xi.Notebook notebook;

	[GtkChild]
	Gtk.Button new_button;

	[GtkChild]
	Gtk.Button open_button;

	[GtkChild]
	Gtk.Button save_button;

    [GtkChild]
	Gtk.MenuButton popover_button;
	
	[GtkChild]
	Gtk.PopoverMenu popover_menu;

	static construct {
		set_css_name("xi-window");
	}

	public Window(Gtk.Application application, CoreConnection core_connection) {
		Object(application: application);
		this.core_connection = core_connection;

		notebook = new Xi.Notebook();
		add(notebook);

		// Actions
		var new_tab_action = new SimpleAction("new-tab", null);
		new_tab_action.activate.connect(() => {
			add_new_tab();
		});
		add_action(new_tab_action);
		var open_action = new SimpleAction("open", null);
		open_action.activate.connect(() => {
			var dialog = new Gtk.FileChooserDialog(null, this, Gtk.FileChooserAction.OPEN, "Cancel", Gtk.ResponseType.CANCEL, "Open", Gtk.ResponseType.ACCEPT);
			dialog.select_multiple = true;
			if (dialog.run() == Gtk.ResponseType.ACCEPT) {
				foreach (var file in dialog.get_files()) {
					add_new_tab(file);
				}
			}
			dialog.destroy();
		});
		add_action(open_action);
		var save_action = new SimpleAction("save", null);
		save_action.activate.connect(() => {
			notebook.get_current_edit_view().get_edit_view().save();
			notebook.get_current_edit_view().get_edit_view().grab_focus();
		});
		add_action(save_action);
		var save_as_action = new SimpleAction("save-as", null);
		save_as_action.activate.connect(() => {
			notebook.get_current_edit_view().get_edit_view().save_as();
			notebook.get_current_edit_view().get_edit_view().grab_focus();
		});
		add_action(save_as_action);
		var find_action = new SimpleAction("find", null);
		find_action.activate.connect(() => {
			notebook.get_current_edit_view().show_find_bar();
		});
		add_action(find_action);
		var close_current_tab_action = new SimpleAction("close-current-tab", null);
		close_current_tab_action.activate.connect(() => {
			close_current_tab();
			notebook.get_current_edit_view().get_edit_view().grab_focus();
		});
		add_action(close_current_tab_action);
		var close_all_tabs_action = new SimpleAction("close-all-tabs", null);
		close_all_tabs_action.activate.connect(() => {
			close_all_tabs();
		});
		add_action(close_all_tabs_action);
	}

	public void add_new_tab(File? file = null) {
		core_connection.send_new_view.begin(file != null ? file.get_path() : null, (obj, res) => {
			string view_id = core_connection.send_new_view.end(res);
			this.notebook.add_edit_view(core_connection, view_id, file);
		});
	}

	[Signal(action = true)]
	public virtual signal void close_current_tab() {
		notebook.remove_page(notebook.get_current_page());
	}

	public void close_all_tabs() {
		int index;
		while (true) {
			index = notebook.get_current_page();
			if (index == -1) {
				break;
			}
			notebook.remove_page(index);
		}
	}
}

}
