
################################################################################

sub draw_item_of_models {

	my $data = $_[0];	

	$_REQUEST {__focused_input} = '_label';

	draw_form ({
	
			right_buttons => [del ($data)],
			
			no_edit => $data -> {is_auto},
			
			path => [
				{type => 'models', name => 'Semaines modèles'},
				{type => 'models', name => $data -> {label}, id => $data -> {id}},
			],
			
		},
		
		$data,
		
		[

#			{
#				name   => 'organisation.label',
#				label  => 'Organisation',
#				type   => 'static',
#			},

			{
				name    => 'label',
				label   => 'Nom',
				size    => 40,
				max_len => 255,
			},

			{
				name   => 'is_odd',
				label  => 'Parité',
				type   => 'radio',
				values => $data -> {voc_oddities},
			},

		],

	)


}

################################################################################

sub draw_models {

	my ($data) = @_;

	return

		draw_table (

			[
				'Nom',
				'Parité',
			],

			sub {

				__d ($i);

				draw_cells ({
					href => "/?type=models&id=$$i{id}",
				},[
	
					$i -> {label},
					$i -> {voc_oddity} -> {label},

				])

			},

			$data -> {models},

			{
				
				name => 't1',
				
				title => {label => 'Semaines modèles'},

				top_toolbar => [{
						keep_params => ['type', 'select'],
					},

					{
						icon  => 'create',
						label => 'Créer',
						href  => {action => 'create'},
					},

					{
						type  => 'input_text',
						label => 'Chercher',
						name  => 'q',
						keep_params => [],
					},

#					{
#						type   => 'input_select',
#						name   => 'id_...',
#						values => $data -> {...},
#						empty  => '[Âñå ...]',
#					},

					{
						type    => 'pager',
					},

					fake_select (),

				],

			}

		);

}

1;
