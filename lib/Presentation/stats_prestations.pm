################################################################################

sub draw_stats_prestations {
	
	my ($data) = @_;

	return

		draw_table (

			[
				$_REQUEST {month} ? 'Utilisateur' : 'Mois',
				(map {{
					label => $_ -> {label_short},
					title => $_ -> {label},
				}} @{$data -> {prestation_types}}),
				'Total',
			],

			sub {

				draw_cells ({
					bold => $i -> {is_total},
				}, [
					{
						label => $i -> {label},
						href => !$_REQUEST {month} ? {month => $i -> {id}} : {id_user => $i -> {id}, month => 0},
					},
					(map {{
						label   => $i -> {by_type} -> {$_ -> {id}},
						picture => '### ### ###',
						off     => 'if zero',
					}} @{$data -> {prestation_types}}),
					{
						label   => $i -> {cnt},
						picture => '### ### ###',
						off     => 'if zero',
						bold    => 1,
					},
				])

			},

			$data -> {lines},

			{
				title => {label => 'Nombre de demi journ�es planifi�es'},
				
				lpt => 1,

				top_toolbar => [{
							keep_params => ['type', 'select'],
						},
					{
						type   => 'input_select',
						name   => 'year',
						values => $data -> {years},
					},
					{
						type   => 'input_select',
						name   => 'month',
						values => $data -> {months},
					},
					{
						type   => 'input_select',
						name   => 'id_site',
						values => $data -> {sites},
						empty  => '[Tout onglet]',
						off    => 0 == @{$data -> {sites}},
					},
					{
						type   => 'input_select',
						name   => 'id_user',
						values => $data -> {users},
						empty  => '[Tous]',
					},
					{
						type   => 'input_select',
						name   => 'is_rh',
						values => [
							{id => +1, label => 'RH'},
							{id => -1, label => 'Non RH'},
						],
						empty  => '[Toutes prestations]',
					},
					{
						type   => 'input_checkbox',
						label  => 'Seulement des personnes',
						name   => 'only_persons',
					},

				],
			}
		);

}

1;
