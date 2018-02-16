/*
* Copyright (c) 2011-2018 Alecaddd (http://alecaddd.com)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
*/

public class Sequeler.Layouts.DataBaseSchema : Gtk.Grid {
	public weak Sequeler.Window window { get; construct; }

	public Gtk.ListStore schema_list;
	public Gtk.ComboBox schema_list_combo;
	public Gtk.TreeIter iter;

	public Gee.HashMap<int, string> schemas;
	private ulong handler_id;

	enum Column {
		SCHEMAS
	}

	public DataBaseSchema (Sequeler.Window main_window) {
		Object (
			orientation: Gtk.Orientation.VERTICAL,
			window: main_window,
			column_homogeneous: true
		);
	}

	construct {
		var dropdown_area = new Gtk.Grid ();
		dropdown_area.column_homogeneous = true;
		dropdown_area.get_style_context ().add_class ("library-titlebar");

		var cell = new Gtk.CellRendererText ();

		schema_list = new Gtk.ListStore (1, typeof (string));
		schema_list.append (out iter);
		schema_list.set (iter, Column.SCHEMAS, _("- Select Database -"));

		schema_list_combo = new Gtk.ComboBox.with_model (schema_list);
		schema_list_combo.pack_start (cell, false);
		schema_list_combo.set_attributes (cell, "text", Column.SCHEMAS);

		schema_list_combo.set_active (0);
		schema_list_combo.margin = 10;
		schema_list_combo.sensitive = false;

		handler_id = schema_list_combo.changed.connect (() => {
			if (schema_list_combo.get_active () == 0) {
				return;
			}
			populate_schema (schemas[schema_list_combo.get_active ()]);
		});

		dropdown_area.attach (schema_list_combo, 0, 0, 1, 1);

		var scroll = new Gtk.ScrolledWindow (null, null);
		scroll.hscrollbar_policy = Gtk.PolicyType.AUTOMATIC;
		scroll.vscrollbar_policy = Gtk.PolicyType.AUTOMATIC;
		scroll.vexpand = true;

		var toolbar = new Gtk.Grid ();
		toolbar.get_style_context ().add_class ("library-toolbar");

		var reload_btn = new Sequeler.Partials.HeaderBarButton ("view-refresh-symbolic", _("Reload Tables"));
		reload_btn.clicked.connect (reload_schema);

		var add_table_btn = new Sequeler.Partials.HeaderBarButton ("list-add-symbolic", _("Add Table"));
		add_table_btn.clicked.connect (add_table);

		toolbar.attach (add_table_btn, 0, 0, 1, 1);
		toolbar.attach (new Gtk.Separator (Gtk.Orientation.VERTICAL), 1, 0, 1, 1);
		toolbar.attach (reload_btn, 2, 0, 1, 1);

		attach (dropdown_area, 0, 0, 1, 1);
		attach (scroll, 0, 1, 1, 2);
		attach (toolbar, 0, 3, 1, 1);
	}

	private void reset_schema_combo () {
		schema_list_combo.disconnect (handler_id);

		schema_list.clear ();
		schema_list.append (out iter);
		schema_list.set (iter, Column.SCHEMAS, _("- Select Database -"));
		schema_list_combo.set_active (0);
		schema_list_combo.sensitive = false;

		handler_id = schema_list_combo.changed.connect (() => {
			if (schema_list_combo.get_active () == 0) {
				return;
			}
			populate_schema (schemas[schema_list_combo.get_active ()]);
		});
	}

	public void reload_schema () {
		var schema = get_schema ();
		reset_schema_combo ();
		
		if (schema == null) {
			return;
		}

		if (window.data_manager.data["type"] == "SQLite") {
			populate_schema (null);
			return;
		}

		Gda.DataModelIter _iter = schema.create_iter ();
		schemas = new Gee.HashMap<int, string> ();
		int i = 1;
		while (_iter.move_next ()) {
			schema_list.append (out iter);
			schema_list.set (iter, Column.SCHEMAS, _iter.get_value_at (0).get_string ());
			schemas.set (i,_iter.get_value_at (0).get_string ());
			i++;
		}

		schema_list_combo.sensitive = true;

		foreach (var entry in schemas.entries) {
			if (window.data_manager.data["name"] == entry.value) {
				schema_list_combo.set_active (entry.key);
			}
		}
	}

	public Gda.DataModel? get_schema () {
		var query = (window.main.connection.db_type as DataBaseType).show_schema ();

		Gda.DataModel? result = null;

		var loop = new MainLoop ();
		window.main.connection.init_select_query.begin (query, (obj, res) => {
			try {
				result = window.main.connection.init_select_query.end (res);
			} catch (ThreadError e) {
				window.main.connection.query_warning (e.message);
				result = null;
			}
			loop.quit ();
		});

		loop.run ();

		return result;
	}

	public void populate_schema (string? table) {
		if (table != null && window.data_manager.data["name"] != table) {
			window.data_manager.data["name"] = table;
			update_connection ();
		}

		warning (table);
	}

	private void update_connection () {
		
	}

	public void add_table () {

	}
}