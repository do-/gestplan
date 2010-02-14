

################################################################################

sub draw_item_of_site_groups {

	my $data = $_[0];	

	$_REQUEST {__focused_input} = '_label';

	draw_form ({
	
			right_buttons => [del ($data)],
			
			no_edit => $data -> {no_del},
			
			path => [
				{type => 'site_groups', name => action_type_label},
				{type => 'site_groups', name => $data -> {label}, id => $data -> {id}},
			],
			
		},
		
		$data,
		
		[
			{
				name    => 'label',
				size    => 40,
			},

		],

	);

}

################################################################################

sub draw_site_groups {

	my ($data) = @_;

	return

		draw_table (

			sub {

				__d ($i);

				draw_cells ({
					href => "/?type=site_groups&id=$$i{id}",
				},[
	
					$i -> {label},

				])

			},

			$data -> {site_groups},

			{
				
				name => 't1',
				
				title => {label => action_type_label},

				top_toolbar => [{
						keep_params => ['type', 'select'],
					},

					{
						icon  => 'create',
						label => 'Créer',
						href  => '?type=site_groups&action=create',
					},

					{
						type  => 'input_text',
						label => 'Chercher',
						name  => 'q',
						keep_params => [],
					},

					{
						type    => 'pager',
					},

					fake_select (),

				],

			}

		);

}

1;
