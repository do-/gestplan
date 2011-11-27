my @templates = (

	{is_odd => 1, label => 'Semaine impaire (1, 3...)'},
	{is_odd => 0, label => 'Semaine paire (2, 4...)'  },

);

foreach my $organisation (@{sql (organisations => [[]])}) {

	my $ids_users = sql_select_ids ('SELECT id FROM users WHERE id_organisation = ?', $organisation -> {id});

	foreach my $template (@templates) {
	
		my $id_model = sql_select_id (models => {

			id_organisation          => $organisation -> {id},
			label                    => $template -> {label},
			is_odd                   => $template -> {is_odd},
			is_auto                  => 1,
			fake                     => 0,

		}, ['id_organisation', 'is_odd', 'is_auto']);

		sql_do ("UPDATE prestation_models SET id_model = ? WHERE id_model IS NULL AND is_odd = ? AND id_user IN ($ids_users)", $id_model, $template -> {is_odd});

	}

}