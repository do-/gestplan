################################################################################

sub draw_rooms {
	
	my ($data) = @_;

	return

		draw_table (

			sub {

				draw_cells ({
					href  => "/?type=rooms&id=$$i{id}",
				}, [
					$i -> {label},
					$i -> {site_label},
				])

			},

			$data -> {rooms},

			{
			
				title => {label => 'Ressources'},

				top_toolbar => [{
						keep_params => ['type'],
					},
				
					{
						icon    => 'create',
						label   => 'Créer',
						href    => '?type=rooms&action=create',
					},

					{
						type    => 'input_text',
						icon    => 'tv',
						label   => 'Chercher',
						name    => 'q',
						keep_params => [],
					},

					{
						type    => 'pager',
						cnt     => 0 + @{$data -> {rooms}},
						total   => $data -> {cnt},
						portion => $data -> {portion},
					},
					
					fake_select (),
					
				],

			}
			
		);

}

################################################################################

sub draw_item_of_rooms {
	
	my ($data) = @_;

	draw_form ({
	
		right_buttons => [ del ($data) ],
		
	}, $data,
		[
			{
				name  => 'label',
				label => 'Désignation',
			},
			{
				name   => 'id_site',
				label  => 'Site',
				type   => 'select',
				empty  => ' ',
				values => $data -> {sites},
			},
		],
	);

}

1;
