

################################################################################

sub draw_item_of_inscriptions_select {

	my ($data) = @_;

	draw_form ({
	
		max_len => 1000,
		
		right_buttons => [ $data -> {read_only} ? () : del ($data) ],
		
		no_edit => $data -> {read_only},
	
	}, $data,
		[
			{
				name  => '_1',
				label => 'Jour',
				type  => 'static',
				value => "$data->{day_name} le $data->{prestation}->{dt_start}",
			},
			{
				name  => 'label',
				label => 'Temps',
				off   => !$_REQUEST {__read_only} || $data -> {prestation} -> {type} -> {is_half_hour} != -1,
			},
			{
				
				type  => 'hgroup',
				label => 'Temps',
				off   => $_REQUEST {__read_only} || $data -> {prestation} -> {type} -> {is_half_hour} != -1,
				
				items => [
					{
						name    => 'hour_start',
						size    => 2,
						value   => $data -> {hour_start} ? sprintf ('%02d', $data -> {hour_start}) : undef,
					},
					{
						name => 'minute_start',
						size => 2,
						value   => sprintf ('%02d', 0 + $data -> {minute_start}),
					},
					{
						label   => 'à',
						name    => 'hour_finish',
						size    => 2,
						value   => $data -> {hour_finish} ? sprintf ('%02d', $data -> {hour_finish}) : undef,
					},
					{
						name => 'minute_finish',
						size => 2,
						value   => sprintf ('%02d', 0 + $data -> {minute_finish}),
					},
				],
				
			},
			{
				name  => 'nom',
				label => 'Nom',
				size  => 40,
			},
			{
				name  => 'prenom',
				label => 'Prénom',
				size  => 40,
			},
			
		],
	)
	
	.
	
	draw_table (
	
		[
			'Nom',
			' ',
			'Prestation',
			'Inscription',
		],
		
		sub {
		
			my $p = $i -> {prestation};
		
			draw_cells ({
				bgcolor => $i -> {is_busy} ? '#eeeeff' : undef,
			}, [
			
				$i -> {label},
				{
					type => 'checkbox',
					name => $p ? 'prestation_' . $p -> {id} : 'user_' . $i -> {id},
					off  => $i -> {is_busy},
				},
				{
					label => $p -> {prestation_type_label},
					href  => "/?type=prestations&id=$$p{id}",
			   	},
			   	"$$p{inscription_label} $$p{inscription_nom} $$p{inscription_prenom}",
			]);
		
		},
		
		$data -> {users},
		
		{
		
			title => {label => 'Co-animateurs'},
			
			name => 't1',
			
			off => !$_REQUEST {__read_only} || $data -> {prestation} -> {type} -> {is_half_hour} != -1,
					
			toolbar => draw_centered_toolbar ({},
				
				[
					{
						icon    => 'create',
						label   => 'ajouter les conseillers séléctionnés',
						href    => "javaScript:if(confirm('Je les ajoute, OK?'))document.forms['t1'].submit()",
					}
				]

			),

		},
	
	)	
	
	;

}


1;
