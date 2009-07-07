################################################################################

sub draw_sites {
	
	my ($data) = @_;

	return

		draw_table (

			sub {

				draw_cells ({
					href  => "/?type=sites&id=$$i{id}",
				}, [
					$i -> {label},
				])

			},

			$data -> {sites},

			{
			
				title => {label => 'Onglets'},

				top_toolbar => [{
						keep_params => ['type'],
					},
				
					{
						icon    => 'create',
						label   => 'Créer',
						href    => '?type=sites&action=create',
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
						cnt     => 0 + @{$data -> {sites}},
						total   => $data -> {cnt},
						portion => $data -> {portion},
					},
					
					fake_select (),
					
				],

			}
			
		);

}

################################################################################

sub draw_item_of_sites {
	
	my ($data) = @_;

	draw_form ({
	
		right_buttons => [ del ($data) ],
		
	}, $data,
		[
			{
				name  => 'label',
				label => 'Désignation',
			},
		],
	);

}

1;
