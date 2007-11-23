################################################################################

sub draw_prestation_types {
	
	my ($data) = @_;

	return

		draw_table (
			
			[
				'Abréviation',
				'Couleur',
				'Demi-jour(s)',
				'Nom',
			],

			sub {

				draw_cells ({
					href  => "/?type=prestation_types&id=$$i{id}",
				}, [
					$i -> {label_short},
					{
						label   => $i -> {prestation_type_group_label},
						bgcolor => $i -> {color},
					},
					$i -> {day_period_label},
					$i -> {label},
				])

			},

			$data -> {prestation_types},

			{
				
				title => {label => 'Prestations'},

				top_toolbar => [{
				
					keep_params => ['type'],
					
				},
					{
						icon    => 'create',
						label   => 'Créer',
						href    => '?type=prestation_types&action=create',
						off     => $_USER -> {role} ne 'admin',
					},

					{
						type    => 'input_text',
						icon    => 'tv',
						label   => 'Chercher',
						name    => 'q',
						keep_params => ['type'],
					},

					{
						type    => 'pager',
						cnt     => 0 + @{$data -> {prestation_types}},
						total   => $data -> {cnt},
						portion => $data -> {portion},
					},
					
					fake_select (),
					
				],

			}
			
		);

}

################################################################################

sub draw_item_of_prestation_types {
	
	my ($data) = @_;

	my $numeros = [
		{
			id    => 0,
			label => '1, 2, 3...',
		},
		{
			id    => 1,
			type  => 'hgroup',
			label => 'horaire',
			items => [
				{
					label => 'en ',
					name  => 'time_step',
					no_colon => 1,
					size  => 2
				},
				{
					label => 'minutes',
					type  => 'static',
					no_colon => 1,
				},
			],
		},
		{
			id    => -1,
			label => 'libre',
		},
	];
	
	my $no_tos = $_REQUEST {__read_only} && $data -> {is_half_hour} != -1;

	draw_form ({

		right_buttons => [ del ($data) ],
		
	}, $data,
		[
			{
				name   => 'id_prestation_type_group',
				label  => 'Couleur',
				type   => 'select',
				values => $data -> {prestation_type_groups},
				empty  => '',
			},
			{
				name  => 'label_short',
				label => 'Abréviation',
				size  => 10,
			},
			{
				name  => 'label',
				label => 'Nom',
				size  => 80,
			},
			[
    				{
					name   => 'is_half_hour',
					label  => 'Numéros',
					type   => 'radio',
					values => $numeros,
				},
				{
					name   => 'id_day_period',
					label  => 'Quand',
					type   => 'checkboxes',
	#				values => $data -> {day_periods},
					values => [
						{
							id    => 1,
							label => 'matin',
							type  => 'hgroup',
							items => [
								{
									name => 'half_1_h',
									size => 2,
								},
								{
									name  => 'half_1_m',
									size  => 2,
									label => 'h ',
									no_colon => 1,
								},
								
								
								
								
								{
									type => 'static',
									value => qq{<span style="visibility:expression(getElementById('$numeros->[-1]') && getElementById('$numeros->[-1]').checked ? 'visible' : 'hidden')">à},
									off   => $no_tos,
								},
								
								{
									name => 'half_1_to_h',
									size => 2,
									off   => $no_tos,
								},
								{
									name  => 'half_1_to_m',
									size  => 2,
									label => 'h ',
									no_colon => 1,
									off   => $no_tos,
								},
								
								{
									type => 'static',
									value => qq{</span>},
									off   => $no_tos,
								},
								
								
								
							],
						},
						{
							id    => 2,
							type  => 'hgroup',
							label => 'après-midi',
							items => [
								{
									name => 'half_2_h',
									size => 2,
								},
								{
									name  => 'half_2_m',
									size  => 2,
									label => 'h ',
									no_colon => 1,
								},
								
								
								
								
								{
									type => 'static',
									value => qq{<span style="visibility:expression(getElementById('$numeros->[-1]') && getElementById('$numeros->[-1]').checked ? 'visible' : 'hidden')">à},
									off   => $no_tos,
								},
								
								{
									name => 'half_2_to_h',
									size => 2,
									off   => $no_tos,
								},
								{
									name  => 'half_2_to_m',
									size  => 2,
									label => 'h ',
									no_colon => 1,
									off   => $no_tos,
								},
								
								{
									type => 'static',
									value => qq{</span>},
									off   => $no_tos,
								},
								
								
								
								
								
								
							],
						},
					],
				},
			],	
			[			
				{
				
					type => 'hgroup',
					label => "Nb d'inscrits",
					
					items => [
						{
							name  => 'length',
							size  => 2,
						},
						{
							name  => 'length_ext',
							label => 'supplémentaires',
							size  => 2,
						},
					],
				
				},
    				
			],
			[
				{
					name  => 'is_placeable_by_conseiller',
					label => 'Délégation',
					type  => 'radio',
					values => [
						{id => 0, label => 'Administrateurs seulement'},
						{id => 1, label => 'Administrateurs et utilisateurs'},
						{
							id     => 2,
							name   => 'ids_users',
							label  => 'Administrateurs et' . ($_REQUEST {__read_only} ? '' : '...'),
							type   => 'checkboxes',
							values => $data -> {users},
							height => 150,
							cols   => 2,
						},
					],
				},
				{
					name  => 'is_private',
					label => 'Inscription privée',
					type  => 'checkbox',
				},
			],						
			[			
				{
					name  => 'is_multiday',
					label => 'Demi-journée et +',
					type  => 'checkbox',
				},
				{
					name  => 'is_to_edit',
					label => 'Ouvrir la fiche',
					type  => 'checkbox',
				},
			],
			{
				name   => 'ids_rooms',
				label  => 'Salle(s) par défaut',
				type   => 'checkboxes',
				cols   => 8,
				values => $data -> {rooms},
			},
			[			
				{
					name   => 'ids_roles',
					label  => 'Affectation',
					type   => 'checkboxes',
					values => $data -> {roles},
				},
				{
					name   => 'id_people_number',
					label  => 'Nb de collaborateurs',
					type   => 'radio',
					values => [
						{id => 1, label => '1'},
						{id => 2, label => '1+'},
						{id => 3, label => 'plusieurs'},
					],
				},
			],
			{
				name   => 'ids_ext_fields',
				label  => 'Données',
				type   => 'checkboxes',
				values => $data -> {ext_fields},
#				height => 150,
				cols   => 3,
			},
			
			{
				name  => 'is_open',
				label => 'Prestation partenariale',
				type  => 'checkbox',
			},
			{
				name  => 'no_stats',
				label => 'Sans statistique',
				type  => 'checkbox',
			},
			{
				name  => 'is_collective',
				label => 'Prestation collective',
				type  => 'checkbox',
			},
			{
				label  => 'Ordre des données',
				type   => 'banner',
				off    => 0 == @{$data -> {ids_ext_fields}},
			},
			
			(map {{
				size  => 4,
				value => $_ -> {ord},
				name  => 'ext_field_' . $_ -> {id},
				label => $_ -> {label},
			}} @{$data -> {ext_fields_ord}})

		],
		
	);

}

1;
