################################################################################

sub draw_item_of_inscriptions {
	
	my ($data) = @_;

	draw_form ({
	
		max_len => 1000,
		
		right_buttons => [ $data -> {read_only} ? () : del ($data) ],
		
		no_edit => $data -> {read_only},
		
		keep_params => ['id_log'],
	
	}, $data,
		[
			{
				name  => '_1',
				label => 'Date',
				type  => 'static',
				value => "$data->{day_name} $data->{prestation}->{dt_start}",
			},
			{
				name  => 'label',
				label => 'Horaire',
				off   => !$_REQUEST {__read_only} || $data -> {prestation} -> {type} -> {is_half_hour} != -1,
			},
			{
				
				type  => 'hgroup',
				label => 'Horaire',
				off   => $_REQUEST {__read_only} || $data -> {prestation} -> {type} -> {is_half_hour} != -1,
				
				items => [
					{
						name    => 'hour_start',
						size    => 2,
						value   => $data -> {hour_start} ? sprintf ('%02d', $data -> {hour_start}) : undef,
					},
					{
						name => 'minute_start',
						label => 'h ',
						no_colon => 1,
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
						label => 'h ',
						no_colon => 1,
						name => 'minute_finish',
						size => 2,
						value   => sprintf ('%02d', 0 + $data -> {minute_finish}),
					},
				],
				
			},
			{
				name  => 'nom',
				label => 'Nom ou objet',
				size  => 40,
			},
			{
				name  => 'prenom',
				label => 'Prénom ou complément',
				size  => 40,
			},
			
			(
				map {{
					type   =>
						$_ -> {id_voc} ? 'select' :
						$_ -> {id_field_type} == 1 ? 'select' :
						$_ -> {id_field_type} == 4 ? 'radio' :
						$_ -> {id_field_type} == 5 ? 'text' :
						'string',
					rows   => $_ -> {id_field_type} == 5 ? 3 : undef,
					cols   => 80,
					label  => $_ -> {label},
					name   => 'field_' . $_ -> {id},
					size   => $_ -> {length},
					values =>
						$_ -> {id_field_type} == 4 ? [{id => 1, label => 'Oui'}, {id => 0, label => 'Non'}] :
						($_ -> {id_field_type} == 1 || $_ -> {id_voc})? ($data -> {'voc_' . $_ -> {id_voc}} || $data -> {users}) :
						undef,
					empty  => ' ',
				}} @{$data -> {ext_fields}},
			),
			
			{
				type  => 'hgroup',
				label => 'Arrivé à',
				
				items => [
					{
						name    => 'hour',
						size    => 2,
						value   => $data -> {hour} ? sprintf ('%02d', $data -> {hour}) : undef,
					},
					{
						name => 'minute',
						size => 2,
						value   => $data -> {hour} ? sprintf ('%02d', $data -> {minute}) : undef,
					},
				],
				
			},
			{
				name   => '_1',
				label  => 'Inscrit par',
				type   => 'static',
				value  => $data -> {author} -> {label},
				off    => !$data -> {prestation} -> {type} -> {is_watched},
			},
			{
				name   => 'id_user',
				label  => 'Reçu par',
				type   => 'select',
				values => $data -> {users},
				empty  => '[personne pour le moment]',
			},
		],
	)
	
	.
	
	draw_table (
	
		[
#			'Heure',
		],
		
		sub {
		
			draw_cells ({
				href => "/?type=inscriptions&id=$$i{id}",
			}, [
			
				$i -> {user_label},
			
			]);
		
		},
		
		$data -> {inscriptions},
		
		{
		
			title => {label => 'Participants'},
			
			off => !$_REQUEST {__read_only} || $data -> {prestation} -> {type} -> {is_half_hour} != -1,
			
			top_toolbar => [ {}, {
			
				label    => 'Ajouter...',
				icon     => 'create',
				keep_esc => 0,
				href     => {type => inscriptions_select},
			
			}]
		
		},
	
	)	
	
	.

	draw_table (

		sub {
		
			draw_cells ({
				href => "?type=prestation_type_files&id=$i->{id}&action=download",
				target => 'invisible',
			},[
				
				$i -> {label},
				
			]),
		
		},
		
		$data -> {prestation_type_files},
		
		{
			
			title => {label => 'Documents'},
			
			off   =>
				!$_REQUEST{__read_only}
				|| 0 == @{$data -> {prestation_type_files}},
			,
			
			name  => 't1',
									
		}

	)

	;

}

################################################################################

sub draw_inscriptions {
	
	my ($data) = @_;
	
	my $title_1 = '';
	
	if ($data -> {prestation_1} -> {id} > 0 && $data -> {prestation_1} -> {id} == $data -> {prestation_2} -> {id}) {
	
		$title_1 .= "$_REQUEST{_day_name} $_REQUEST{dt} la journée entière : " if $data -> {prestation_1} -> {dt_start} eq $data -> {prestation_1} -> {dt_finish};
		$title_1 .= $data -> {prestation_1} -> {type} -> {label};
		$title_1 .= ' du ';

		my ($y, $m, $d) = split /-/, $data -> {prestation_1} -> {dt_start};		
		
		$title_1 .= $day_names [ Day_of_Week ($y, $m, $d) - 1 ];		
		$title_1 .= ", $d/$m ";

		$title_1 .= ' au ';

		my ($y, $m, $d) = split /-/, $data -> {prestation_1} -> {dt_finish};		
		
		$title_1 .= $day_names [ Day_of_Week ($y, $m, $d) - 1 ];		
		$title_1 .= ", $d/$m ";
		
	
	}
	else {
		
		$title_1 = "$_REQUEST{_day_name} $_REQUEST{dt} matin: ";
		$title_1 .= $data -> {prestation_1} -> {type} -> {label} || 'Libre';
	
	}
	
	
	
	
	
	
	
	

	return
			
		draw_toolbar (
					{
						keep_params => ['type'],
					},
					{
						type         => 'button',
						icon		 => 'cancel',
						label        => 'retour (Esc)',
						hotkey       => {code => Esc},
						href         => "/?type=prestations&week=$_REQUEST{_week}&year=$_REQUEST{_year}&id_site=$_REQUEST{id_site}&aliens=$_REQUEST{aliens}",
					},
					{
						type         => 'input_select',
						name         => 'id_user',
						values       => $data -> {users},
					},
					$data -> {prevnext} -> {-1},
					{
						type         => 'input_date',
#						label		 => 'pour',
						name         => 'dt',
						no_read_only => 1,
					},		
					$data -> {prevnext} -> {1},
					{
						type         => 'input_select',
						name         => 'id_day_period',
						values       => $data -> {day_periods},
					},
			)
		
		.

		draw_table (
		
			(0 + @{$data -> {prestation_1} -> {inscriptions}} ? [
				{label => ' ', attributes => {width => '1%'}},
				'Nom, Prénom ou Objet',
				'Arrivé',
				'Reçu par',
				map {$_ -> {label}} @{$data -> {prestation_1} -> {ext_fields}},
			] : ()),

			sub {
			
				my $c_est_mon_organisation = ($data -> {prestation_1} -> {id_organisation} == $_USER -> {id_organisation});

				if ($i -> {is_note}) {
					
					$i -> {label} =~ s{\n}{<br>}gsm;

					return draw_cells ({}, [
						{
							label   => '<b>Note:</b> ' . $i -> {label},
							colspan => 4 + @{$data -> {prestation_1} -> {ext_fields}},
							max_len => 10000,
							no_nobr => 1,
						},
					]);
					
				}
				elsif ($i -> {fake} == 0 && !(
				
					$c_est_mon_organisation or ($i -> {id_organisation} == $_USER -> {id_organisation}) or !$i -> {id_organisation}
				
				)) {
					

					return draw_cells ({}, [
						$i -> {label},
						{
							label   => 'Réservé',
							colspan => 3 + @{$data -> {prestation_1} -> {ext_fields}},
							max_len => 10000,
							no_nobr => 1,
						},
					]);
					
				}
							
			    my $mark_href = {href => '/?type=inscriptions&action=mark&id=' . $i -> {id}};
			    check_href ($mark_href);

				draw_cells ({
					href  =>
						$data -> {prestation_1} -> {read_only} || (
							$i -> {fake} && (
								0
								|| !$data -> {prestation_1} -> {present_users}
								|| $data -> {week_status_type} -> {id} != 2
							)
						) ? undef :
						"/?type=inscriptions&id=$$i{id}",
					strike => 0,
				}, [
					$i -> {label},
					{
						status => $i -> {is_unseen} ? {icon => 100} : undef,
						label => $i -> {fake} ? '[libre]' : join ' ', ($i -> {nom}, $i -> {prenom}),
					},
					{
						label => sprintf ('%02dh%02d', $i -> {hour}, $i -> {minute}),
						off   => !$i -> {hour},
						
						attributes => {						
						    ondblclick => $i -> {hour} || $i -> {fake} ? '' : "if (confirm (\"$$i{prenom} $$i{nom} est arrivé(e) ?\")) {nope (\"$$mark_href{href}\", \"invisible\"); nop ();}"	
						},
						
					},
					{
						label => map {$_ -> {label}} grep {$_ -> {id} == $i -> {id_user}} @{$data -> {users}},
#						off   => !$i -> {hour},
					},
					map {$i -> {'field_' . $_ -> {id_ext_field}}} @{$data -> {prestation_1} -> {ext_fields}},
				])

			},

			$data -> {prestation_1} -> {inscriptions},

			{
				
				title => {label => $title_1},
				
				off => $_REQUEST {id_day_period} == 2,
				
				lpt => 1,

				top_toolbar => [ {},
									
					{
						icon  => 'create',
						href  => "/?type=inscriptions&action=create&id_prestation=" . $data -> {prestation_1} -> {id},
						label => 'Nouveau rendez-vous',
						off   =>
							$data -> {prestation_1} -> {type} -> {is_half_hour} != -1 ||
							(
								$_USER -> {role} ne 'admin'
								&& $data -> {prestation_1} -> {type} -> {is_private}
								&& $data -> {prestation_1} -> {id_user}  != $_USER -> {id}
								&& $data -> {prestation_1} -> {id_users} !~ /,$_USER->{id},/
#								&& $data -> {prestation_1} -> {type} -> {ids_roles} !~ /,$_USER->{id_role},/
							)
							,
					},

					{
						icon  => 'edit',
						href  => "/?type=prestations&id=" . $data -> {prestation_1} -> {id},
						label => 'Déplacer',
						off =>
							$_USER -> {role} ne 'admin' ||
							$data -> {week_status_type} -> {id} == 3 ||
							$data -> {user} -> {id_organisation} != $_USER -> {id_organisation}
					},
				
				],

			}
			
		)
		
		.
		
		draw_table (

			(0 + @{$data -> {prestation_2} -> {inscriptions}} ? [
				{label => ' ', attributes => {width => '1%'}},
				'Nom, Prénom ou Objet',
				'Arrivé',
				'Reçu par',
				map {$_ -> {label}} @{$data -> {prestation_2} -> {ext_fields}},
			] : ()),
			
			sub {

				my $c_est_mon_organisation = ($data -> {prestation_2} -> {id_organisation} == $_USER -> {id_organisation});

				if ($i -> {is_note}) {
					
					$i -> {label} =~ s{\n}{<br>}gsm;
					
					return draw_cells ({}, [
						{
							label   => '<b>Note:</b> ' . $i -> {label},
							colspan => 4 + @{$data -> {prestation_2} -> {ext_fields}},
							max_len => 100000,
							no_nobr => 1,
						},
					]);
					
				}
				elsif ($i -> {fake} == 0 && !(
				
					$c_est_mon_organisation or ($i -> {id_organisation} == $_USER -> {id_organisation} or !$i -> {id_organisation})
				
				)) {
					

					return draw_cells ({}, [
						$i -> {label},
						{
							label   => 'Réservé',
							colspan => 3 + @{$data -> {prestation_1} -> {ext_fields}},
							max_len => 10000,
							no_nobr => 1,
						},
					]);
					
				}

			    my $mark_href = {href => '/?type=inscriptions&action=mark&id=' . $i -> {id}};
			    check_href ($mark_href);

				draw_cells ({
					href  =>
						$data -> {prestation_2} -> {read_only} || (
							$i -> {fake} && (
								!$data -> {prestation_2} -> {present_users}
								|| $data -> {week_status_type} -> {id} != 2
							)
						) ? undef :
						"/?type=inscriptions&id=$$i{id}",
					strike => 0,
				}, [
					$i -> {label},
					{
						status => $i -> {is_unseen} ? {icon => 100} : undef,
						label => $i -> {fake} ? '[libre]' : join ' ', ($i -> {nom}, $i -> {prenom}),
					},
					{
						label => sprintf ('%02dh%02d', $i -> {hour}, $i -> {minute}),
						off   => !$i -> {hour},
						attributes => {						
						    ondblclick => $i -> {hour} || $i -> {fake} ? '' : "if (confirm (\"$$i{prenom} $$i{nom} est arrivé(e) ?\")) {nope (\"$$mark_href{href}\", \"invisible\"); nop ();}"	
						},
					},
					{
						label => map {$_ -> {label}} grep {$_ -> {id} == $i -> {id_user}} @{$data -> {users}},
#						off   => !$i -> {hour},
					},
					map {$i -> {'field_' . $_ -> {id_ext_field}}} @{$data -> {prestation_2} -> {ext_fields}},
				])

			},

			$data -> {prestation_2} -> {inscriptions},

			{
				
				title => {label => "$_REQUEST{_day_name} $_REQUEST{dt}" . ' après-midi : ' . ($data -> {prestation_2} -> {type} -> {label} || 'libre')},
				
				off => $data -> {prestation_1} -> {id} == $data -> {prestation_2} -> {id} || $_REQUEST {id_day_period} == 1,

				lpt => 1,
				
				top_toolbar => [ {},
				
					{
						icon  => 'create',
						href  => "/?type=inscriptions&action=create&id_prestation=" . $data -> {prestation_2} -> {id},
						label => 'Nouveau rendez-vous',
						off   =>
							$data -> {prestation_2} -> {type} -> {is_half_hour} != -1
							|| (
								$_USER -> {role} ne 'admin'
								&& $data -> {prestation_2} -> {type} -> {is_private}
								&& $data -> {prestation_2} -> {id_user}  != $_USER -> {id}
								&& $data -> {prestation_2} -> {id_users} !~ /,$_USER->{id},/
#								&& $data -> {prestation_2} -> {type} -> {ids_roles} !~ /,$_USER->{id_role},/
							)
							,
					},
					
					{
						icon  => 'edit',
						href  => "/?type=prestations&id=" . $data -> {prestation_2} -> {id},
						label => 'Déplacer',
						off =>
							$_USER -> {role} ne 'admin' ||
							$data -> {week_status_type} -> {id} == 3 ||
							$data -> {user} -> {id_organisation} != $_USER -> {id_organisation}
					},
				
				],

			}
			
		)
		
		.
		
		iframe_alerts ()
		
		;

}

1;
