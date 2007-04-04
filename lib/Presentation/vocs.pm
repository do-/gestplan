################################################################################

sub draw_vocs {
	
	my ($data) = @_;

	return

		draw_table (

			sub {

				draw_cells ({
					href  => "/?type=vocs&id=$$i{id}",
				}, [
					$i -> {label},
				])

			},

			$data -> {vocs},

			{
				
				title => {label => 'Listes de choix'},

				top_toolbar => [{
					keep_params => ['type', 'select'],
				},
					{
						icon    => 'create',
						label   => 'Créer',
						href    => '?type=vocs&action=create',
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
						cnt     => 0 + @{$data -> {vocs}},
						total   => $data -> {cnt},
						portion => $data -> {portion},
					},
					
					$fake_select,
					
				],

			}
			
		);

}

################################################################################

sub draw_item_of_vocs {
	
	my ($data) = @_;

	draw_form ({
		
		right_buttons => [ del ($data) ],
	
	}, $data,
	
		[
			{
				name  => 'label',
				label => 'Désignation de la liste',
				size  => 50,
			},
		],
		
	)
	
	.
	
		draw_table (

			sub {

				draw_cells ({
					href  => "/?type=voc_items&id=$$i{id}&id_voc=$$data{id}",
				}, [
					$i -> {ord},
					$i -> {label},
				])

			},

			$data -> {items},

			{
				
				title => {label => 'Éléments'},
				
				off => !$_REQUEST {__read_only},

				top_toolbar => [{
				
						keep_params => ['type', 'id'],
				
					},
				
					{
						icon    => 'create',
						label   => 'Créer',
						href    => '/?type=voc_items&action=creer&id_voc=' . $data -> {id},
						keep_esc => 0,
					},
					
					$fake_select,
					
				],

			}
			
		);
	
	
	
	
	
	
	
	
	
	;

}

1;
