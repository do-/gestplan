################################################################################

sub draw_item_of_ext_fields {
	
	my ($data) = @_;

	draw_form ({
	    	
		right_buttons => [ del ($data) ],
		
	}, $data,
		[
			{
				name  => 'ord',
				label => 'Ordre',
				size  => 4,
			},
			{
				name  => 'label',
				label => 'Désignation',
				size  => 40,
			},
			{
				name   => 'id_field_type',
				label  => 'Nature',
				type   => 'radio',
				values => $data -> {ext_field_types},
			},
		],
	);

}

################################################################################

sub draw_ext_fields {
	
	my ($data) = @_;

	return

		draw_table (
		
			['Ordre', 'Désignation', 'Nature', 'Dimension', 'Liste'],
		
			sub {

				draw_cells ({
					href  => "/?type=ext_fields&id=$$i{id}",
				}, [
					$i -> {ord},
					$i -> {label},
					$i -> {ext_field_types_label},
					$i -> {length},
					($i -> {id_field_type} == 1 && !$i -> {id_voc} ? 'Utilisateurs' : $i -> {voc_label}),
				])

			},

			$data -> {ext_fields},

			{
	
				title => {label => 'Types de données'},

				top_toolbar => [{
					
					keep_params => ['type'],
					
				},
					{
						icon    => 'create',
						label   => 'Créer',
						href    => '/?type=ext_fields&action=create',
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
						cnt     => 0 + @{$data -> {ext_fields}},
						total   => $data -> {cnt},
						portion => $data -> {portion},
					},
					
					fake_select (),
					
					
				],

			}
			
		);

}

1;
