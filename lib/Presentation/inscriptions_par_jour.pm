################################################################################

sub draw_inscriptions_par_jour {
	
	my ($data) = @_;

	return

	    draw_form (
		
			{
				
				menu => $data -> {menu},
				
				bottom_toolbar => ' ',

				max_len => 255,
				
				off => $_REQUEST {xls},

			},
			
			
			{
				path => [{
					name => "Liste récapitulative",					
				}],
			},
		
			[],
		)
		
		.

		draw_table (
		
			[
				'Nom, prénom ou Objet',
				'Utilisateur',
				'Date',
				'Type',
				'No / temps',
				'Arrivé',
				'Reçu par',
				map {$_ -> {label}} grep {$_ -> {type} ne 'break'} @{$data -> {ext_fields}},
			],			

			sub {
			
				__d ($i, 'dt_start');

			    my $mark_href = {href => '/?type=inscriptions&action=mark&id=' . $i -> {id}};
			    check_href ($mark_href);

				draw_cells ({
					href  => "/?type=inscriptions&id=$$i{id}",
				}, [
					(join ' ', ($i -> {nom}, $i -> {prenom})),
					$i -> {user_label},
					$i -> {dt_start},
					$i -> {label_short},
					$i -> {label},
					{
						label => sprintf ('%02dh%02d', $i -> {hour}, $i -> {minute}),
						off   => !$i -> {hour},
						
						attributes => {						
						    ondblclick => $i -> {hour} || $i -> {fake} ? '' : "if (confirm (\"$$i{nom} $$i{prenom} est arrivé(e) ?\")) {nope (\"$$mark_href{href}\", \"invisible\"); nop ();}"	
						},
						
					},
					{
						label => $i -> {recu_par},
#						off   => !$i -> {hour},
					},
					map {
						{
							label   => $i -> {'field_' . $_ -> {id}},
							max_len => 100000,
						}
					}  grep {$_ -> {type} ne 'break'} @{$data -> {ext_fields}},
				])

			},

			$data -> {inscriptions_par_conseiller},

			{
			
#				title => {label => 'Liste récapitulative'},
				
				lpt => 1,

				top_toolbar => [{
					keep_params => ['type', 'year', 'week'],
				},
	
					{
						type   => 'input_date',
						name   => 'dt_from',
						no_read_only => 1,
						label  => 'Du'
					},
					{
						type   => 'input_date',
						name   => 'dt_to',
						no_read_only => 1,
						label  => 'au'
					},
					{
						type   => 'input_select',
						name   => 'half_start',
						values => [
							{id => 1, label => 'Matin'},
							{id => 2, label => 'Après-midi'},
						],
						empty  => '[Tous]',
					},
					{
						type   => 'input_select',
						name   => 'id_user',
						values => $data -> {users},
						empty  => '[Tout utilisateur]',
					},
					{
						type   => 'input_select',
						name   => 'id_prestation_type',
						values => $data -> {prestation_types},
						empty  => '[Tout type]',
					},
					{
						type   => 'input_text',
						name   => 'q',
						keep_params => [],
						label  => 'Nom'
					},
					{
						type    => 'pager',
						total   => $data -> {cnt},
						cnt     => 0 + @{$data -> {inscriptions_par_conseiller}},
						portion => $data -> {portion},
					},
					{
						type         => 'button',
						icon		 => 'cancel',
						label        => 'retour (Esc)',
						hotkey       => {code => Esc},
						href         => ($_REQUEST {week} ? "/?type=prestations&week=$_REQUEST{week}" : "/?type=prestations_month&month=$_REQUEST{month}") . "&year=$_REQUEST{year}&id_site=$_REQUEST{id_site}&aliens=$_REQUEST{aliens}",
					},
					
					@{$data -> {ext_fields}},
					
				],

			}
			
		);


}

1;
