

################################################################################

sub draw_item_of_prestation_type_files {

	my ($data) = @_;

	$_REQUEST {__focused_input} = '_file';

	draw_form ({
	
			right_buttons => [del ($data)],
			
			path => [
				{type => 'prestation_types', name => 'Prestations'},
				{type => 'prestation_types', name => $data -> {prestation_type} -> {label}, id => $data -> {prestation_type} -> {id}},
				{type => 'prestation_type_files', name => $data -> {label}, id => $data -> {id}},
			],
			
		},
		
		$data,
		
		[
			{
				name    => 'file',
				label   => 'Fichier',
				size    => 64,
				type    => 'file',
			},
			{
				name    => 'label',
				label   => 'Nom',
				size    => 80,
				max_len => 255,
			},
		],
	)

}


1;
