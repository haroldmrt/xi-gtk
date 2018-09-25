// Copyright 2016-2018 Elias Aebi
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

class Application: Gtk.Application {
	private CoreConnection core_connection;

	public Application() {
		Object(application_id: "com.github.eyelash.xi-gtk", flags: ApplicationFlags.HANDLES_OPEN);
	}

	private unowned Xi.Window get_current_window() {
		return get_active_window() as Xi.Window;
	}

	private void load_css(string resource_path) {
		var css_provider = new Gtk.CssProvider();
		css_provider.load_from_resource(resource_path);
		Gtk.StyleContext.add_provider_for_screen(Gdk.Screen.get_default(), css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
	}

	public override void startup() {
		base.startup();

		load_css("/com/github/eyelash/xi-gtk/key-bindings.css");
		load_css("/com/github/eyelash/xi-gtk/style.css");

		var quit_action = new SimpleAction("quit", null);
		quit_action.activate.connect(() => {
			foreach (weak Gtk.Window window in get_windows()) {
				window.close();
			}
		});
		add_action(quit_action);

		set_accels_for_action("win.new-tab", {"<Primary>N"});
		set_accels_for_action("win.open", {"<Primary>O"});
		set_accels_for_action("win.save", {"<Primary>S"});
		set_accels_for_action("win.save-as", {"<Primary><Shift>S"});
		set_accels_for_action("win.find", {"<Primary>F"});
		set_accels_for_action("app.quit", {"<Primary>Q"});

		unowned string core_binary = GLib.Environment.get_variable("XI_CORE");
		if (core_binary == null) {
			core_binary = "xi-core";
		}
		core_connection = new CoreConnection({core_binary});
		core_connection.def_style_received.connect((style) => {
			StyleMap.get_instance().def_style(style);
		});
		core_connection.theme_changed_received.connect((name, theme) => {
			Theme.get_instance().set_from_json(theme);
		});
		string config_dir = GLib.Path.build_filename(GLib.Environment.get_user_config_dir(), "xi-gtk");
		GLib.DirUtils.create_with_parents(config_dir, 0777);
		core_connection.send_client_started(config_dir, Config.PLUGIN_DIR);
		unowned string theme = GLib.Environment.get_variable("XI_THEME");
		if (theme == null) {
			theme = "InspiredGitHub";
		}
		core_connection.send_set_theme(theme);

		var window = new Xi.Window(this, core_connection);
		window.show_all();
	}

	public override void activate() {
		get_current_window().add_new_tab();
	}

	public override void open(File[] files, string hint) {
		foreach (var file in files) {
			get_current_window().add_new_tab(file);
		}
	}

	public static int main(string[] args) {
		var app = new Application();
		return app.run(args);
	}
}

}
