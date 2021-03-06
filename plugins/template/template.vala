/*
 * Template a plugin for Diodon
 * Copyright (C) 2014 Christian Timothy Johnson <_c_@mail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published
 * by the Free Software Foundation, either version 2 of the License, or (at
 * your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
 * License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

using Gtk;

namespace Diodon.Plugins
{

	/*
	 * Template Plugin for Diodon
	 *
	 * @author RedHatter <_c_@mail.com>
	 */
	public class TemplatePlugin : Peas.ExtensionBase, Peas.Activatable, PeasGtk.Configurable
	{
		private Controller controller;
		private Gtk.MenuItem item;
		private string accelerator;
		private GLib.Settings _settings;
		private GLib.Settings settings
		{
			get
			{
				if (_settings == null)
					_settings = new GLib.Settings ("com.diodon.plugins.template");
				
				return _settings;
			}
		}

		public Object object { get; construct; }

		public TemplatePlugin ()
		{
			Object ();
		}

		public void activate ()
		{
			debug ("activate");
			controller = object as Controller;

			// Register keybinding and create menu item
			accelerator = settings.get_string ("accelerator");
			bind_accelerator (accelerator);
			if (settings.get_boolean ("display"))
				create_item ();

			// Watch for changes in Preferences
			settings.changed.connect ( (key) => {
				if (settings.get_boolean ("display"))
					create_item ();
				else
					destroy_item ();

				string new_accelerator = settings.get_string ("accelerator");
				if (new_accelerator != accelerator) {
					bind_accelerator (new_accelerator);
				}
			});
		}

		/*
		 * Create Run Template item to add to menu.
		 */
		private void create_item ()
		{
			if (item != null)
				return;

			debug ("create item");

			item = new Gtk.MenuItem.with_label ("Run Template");
			item.activate.connect ( () => template.begin ());
			add_item (controller.get_recent_menu ());
			controller.on_recent_menu_changed.connect (add_item);
		}

		/*
		 * Insert item into menu.
		 */
		private void add_item (Gtk.Menu menu)
		{
				menu.insert (item, controller.get_configuration ().recent_items_size + 1);
				item.show ();			
		}

		/*
		 * Remove item from menu.
		 */
		private void destroy_item ()
		{
			debug ("destroy item");

			controller.on_recent_menu_changed.disconnect (add_item);
			controller.get_recent_menu ().remove (item);
			item = null;
		}

		/*
		 * Registers the specified keybinding with the Diodon keybinding
		 * manager.
		 */
		private void bind_accelerator (string new_accelerator)
		{
			debug ("bind_accelerator: %s", new_accelerator);
			var keybinding_manager = controller.get_keybinding_manager ();
			if (accelerator != null) {
				keybinding_manager.unbind (accelerator);
				debug ("unbinding %s", accelerator);
			}
			keybinding_manager.bind (new_accelerator, () => template.begin ());
			accelerator = new_accelerator;
		}

		public void deactivate ()
		{
			debug ("deactivate");
			
			controller.get_keybinding_manager ().unbind (accelerator);
			destroy_item ();
		}

		public void update_state () {}

		/*
		 * Code goes here.
		 */
		private async void template ()
		{
		}

		/*
		 * Creates the Preferences window in Diodon's Plugin Preferences.
		 */
		public Gtk.Widget create_configure_widget ()
		{
			accelerator = settings.get_string ("accelerator");

			var box = new Gtk.Grid ();
			box.attach (new Gtk.Label ("Template Key"), 0, 0, 1, 1);
			var accel_entry = new Gtk.Entry ();
			accel_entry.set_text (accelerator);
			accel_entry.focus_out_event.connect ( () => {
				var text = accel_entry.get_text ();
				if (text != null) {
					settings.set_string ("accelerator", text);
				}
				return false;
			});
			box.attach (accel_entry, 1, 0, 1, 1);

			var check = new Gtk.CheckButton.with_label ("Display in menu");
			check.active = settings.get_boolean ("display");
			check.toggled.connect ( () => settings.set_boolean ("display", check.active));
			box.attach (check, 0, 2, 2, 1);
			box.show_all ();

			return box;
		}

	}
}

[ModuleInit]
public void peas_register_types (GLib.TypeModule module)
{
	Peas.ObjectModule objmodule = module as Peas.ObjectModule;
	objmodule.register_extension_type (typeof (Peas.Activatable),
									   typeof (Diodon.Plugins.TemplatePlugin));
	objmodule.register_extension_type (typeof (PeasGtk.Configurable),
									   typeof (Diodon.Plugins.TemplatePlugin));

}
