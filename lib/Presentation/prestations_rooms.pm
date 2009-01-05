################################################################################

sub draw_item_of_prestations_rooms {
	
	my ($data) = @_;

	draw_form ({
	
		right_buttons => [ del ($data) ],
	
	}, $data,
		[
			
			{
				name   => 'id_room',
				label  => 'Ressource',
				type   => 'select',
				values => $data -> {rooms},
				empty  => '[Veuillez choisir la ressource]',
			},
			
			[
				{
					type   => 'hgroup',
					label  => 'Du',
					items  => [
					
						{
							type => 'date',
							name => 'dt_start',
							no_read_only => 1,
							read_only => 0 < @{$data -> {inscriptions}},
							add_hidden => 1,
						},
						{
							type   => 'select',
							name   => 'half_start',
							values => $data -> {day_periods},
							read_only => 0 < @{$data -> {inscriptions}},
							add_hidden => 1,
						},
										
					],
				},
				{
					type   => 'hgroup',
					label  => "au",
					items  => [
					
						{
							type => 'date',
							name => 'dt_finish',
							no_read_only => 1,
							read_only => 0 < @{$data -> {inscriptions}},
							add_hidden => 1,
						},
						{
							type  => 'select',
							name  => 'half_finish',
							values => $data -> {day_periods},
							read_only => 0 < @{$data -> {inscriptions}},
							add_hidden => 1,
						},
										
					],
				},
			],
		],
	);

}

1;
