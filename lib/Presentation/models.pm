
################################################################################

sub draw_item_of_models {

	my $data = $_[0];	

	$_REQUEST {__focused_input} = '_label';

	draw_form ({
	
			right_buttons => [del ($data)],
			
			no_edit => $data -> {is_auto},
			
			path => [
				{type => 'models', name => 'Semaines mod�les'},
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
				label  => 'Parit�',
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
				'Parit�',
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
				
				title => {label => 'Semaines mod�les'},

				top_toolbar => [{
						keep_params => ['type', 'select'],
					},

					{
						icon  => 'create',
						label => 'Cr�er',
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
#						empty  => '[��� ...]',
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
