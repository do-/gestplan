################################################################################

sub draw_stats_inscriptions {
	
	my ($data) = @_;

	return

		draw_table (

			[
				$_REQUEST {month} ? 'Utilisateur' : 'Mois',
				(map {
					$_ -> {label},
				} @{$data -> {prestation_types}}),
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
				title => {label => 'Nombre de jeunes reçus'},
				
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
						empty  => '[Tout site]',
						off    => 0 == @{$data -> {sites}},
					},
					{
						type   => 'input_select',
						name   => 'id_user',
						values => $data -> {users},
						empty  => '[Tous]',
					},

				],
			}
		);

}

1;
