################################################################################

sub draw_item_of_prestation_type_groups {
	
	my ($data) = @_;

	draw_form ({

		right_buttons => $data -> {id} < 0 ? [] : [ del ($data) ],

	}, $data,
		[
			{
				name  => 'label',
				label => 'Designation',
				size  => 60,
				read_only => $data -> {id} < 0,
				add_hidden => 1,
			},
			{
				name  => 'color',
				label => 'Couleur',
				type  => 'color',
#				value => $data -> {color},
			},
		],
	);

}

################################################################################

sub draw_prestation_type_groups {
	
	my ($data) = @_;

	return

		draw_table (

			sub {

				draw_cells ({
					href  => "/?type=prestation_type_groups&id=$$i{id}",
				}, [
					$i -> {label},
					{
						label   => 'Test',
						bgcolor => $i -> {color},
					},
				])

			},

			$data -> {prestation_type_groups},

			{
				title => {label => 'Groupes de types de prestations'},

				top_toolbar => [{
						keep_params => ['type'],
					},
					{
						icon    => 'create',
						label   => 'Créer',
						href    => '?type=prestation_type_groups&action=create',
					},

#					{
#						type    => 'input_text',
#						icon    => 'tv',
#						label   => 'Chercher',
#						name    => 'q',
#					},

					{
						type    => 'pager',
						cnt     => 0 + @{$data -> {prestation_type_groups}},
						total   => $data -> {cnt},
						portion => $data -> {portion},
					},
					
					$fake_select,
					
				],

			}
			
		);

}

1;
