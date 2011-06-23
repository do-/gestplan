################################################################################

sub draw_item_of_voc_items {
	
	my ($data) = @_;

	draw_form ({
		
		right_buttons => [ del ($data) ],
		
		keep_params => ['id_voc'],
		
	}, $data,
		[
			{
				name  => 'ord',
				label => 'Ordre',
				size  => 2,
			},
			{
				name  => 'label',
				label => 'Désignation',
				size  => 100,
				max_len => 255,
			},
		],
	);

}

1;
