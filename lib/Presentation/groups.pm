################################################################################

sub draw_groups {
	
	my ($data) = @_;

	return

		draw_table (

			sub {

				draw_cells ({
					href  => "/?type=groups&id=$$i{id}",
				}, [
					{
						label => $i -> {ord},
						picture => '###',
						attributes => {width => 50},
					},	
					$i -> {label},
				])

			},

			$data -> {groups},

			{
			
				title => {label => 'Regroupements'},

				top_toolbar => [{
						keep_params => ['type'],
					},
				
					{
						icon    => 'create',
						label   => 'Créer',
						href    => '?type=groups&action=create',
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
						cnt     => 0 + @{$data -> {groups}},
						total   => $data -> {cnt},
						portion => $data -> {portion},
					},
					
					$fake_select,
					
				],

			}
			
		);

}

################################################################################

sub draw_item_of_groups {
	
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
				name  => 'ord',
				label => 'Ordre',
				size  => 5,
			},
		],
	);

}

1;
