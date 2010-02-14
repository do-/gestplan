################################################################################

sub draw_sites {
	
	my ($data) = @_;

	return

		draw_table (

			sub {

				draw_cells ({
					href  => "/?type=sites&id=$$i{id}",
				}, [
					{
						label   => $i -> {ord},
						picture => '#####',
						attributes => {width => 1},
					},
					$i -> {label},
					{
						label  => $i -> {site_group} -> {label},
						hidden => 0 == @{$data -> {site_groups}},
					},
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
						type    => 'input_select',
						name    => 'id_site_group',
						values  => $data -> {site_groups},
						empty   => '[Tout secteur]',
						off     => 0 == @{$data -> {site_groups}},
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
	
	$_REQUEST {__focused_input} = '_label';

	draw_form ({
	
		right_buttons => [ del ($data) ],
		
	}, $data,
		[
			{
				name    => 'ord',
				label   => 'Ordre',
				picture => '#####',
				size    => 5,
			},
			{
				name    => 'label',
				label   => 'Désignation',
			},
			{
				name    => 'id_site_group',
				off     => 0 == @{$data -> {site_groups}},
				empty   => '',
			},
		],
	);

}

1;
