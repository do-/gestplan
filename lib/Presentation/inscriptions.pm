################################################################################

sub draw_item_of_inscriptions {
	
	my ($data) = @_;

	draw_form ({
	
		max_len => 1000,
		
		additional_buttons => [
		
			{
				label  => 'dupliquer (F6)',
				hotkey => {code => F6},
				icon   => 'create',
				href   => "/?type=prestations&id_inscription_to_clone=$$data{id}",
				keep_esc => 1,
				off    => !$_REQUEST {__read_only},
			},
			
		],
		
		left_buttons => [
			{
				icon     => 'left',
				label    => "$data->{prev}->{label} $data->{prev}->{nom} $data->{prev}->{prenom}",
				href     => {id => $data -> {prev} -> {id}},
				off      =>
					!$_REQUEST {__read_only}
					|| !$data -> {prev} -> {id}
				,
				keep_esc => 0,
				hotkey   => {code => 37},
			},
		],
		
		right_buttons => [

			($data -> {read_only} ? () : del ($data)),

			{
				icon     => 'right',
				label    => "$data->{next}->{label} $data->{next}->{nom} $data->{next}->{prenom}",
				href     => {id => $data -> {next} -> {id}},
				off      =>
					!$_REQUEST {__read_only}
					|| !$data -> {next} -> {id}
				,
				keep_esc => 0,
				hotkey   => {code => 39},
			},
			
		],		
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
				off   => $data -> {prestation} -> {type} -> {is_anonymous},
			},
			{
				name  => 'prenom',
				label => 'Prénom ou complément',
				size  => 40,
				off   => $data -> {prestation} -> {type} -> {is_anonymous},
			},
			
			(
			
			
				map {
				
					my $values = $data -> {'voc_' . $_ -> {id_voc}} || $data -> {users};
				
				{
					type   =>
						$_ -> {id_field_type} == 1 ? 'select' :
						$_ -> {id_field_type} == 8 ? 'checkboxes' :
						$_ -> {id_field_type} == 4 ? 'radio' :
						$_ -> {id_field_type} == 5 ? 'text' :
						($_ -> {id_field_type} == 6 && !$_REQUEST {__read_only}) ? 'file' :
						$_ -> {id_field_type} == 7 ? 'checkbox' :
						'string',
					rows   => $_ -> {id_field_type} == 5 ? 3 : undef,
					cols   => $_ -> {id_field_type} == 8 ? 3 : 80,
					href   => $_ -> {id_field_type} == 6 ?
						qq{/?type=ext_field_values&id=$data->{"field_$_->{id}_id"}&action=download} :
						undef,
					height => @$values > 7 ? 150 : undef,
					target => 'invisible',
					max_len => 100,
					label  => $_ -> {label},
					name   => 'field_' . $_ -> {id},
					size   => $_ -> {length},
					values =>
						$_ -> {id_field_type} == 4 ? [{id => 1, label => 'Oui'}, {id => 0, label => 'Non'}] :
						($_ -> {id_field_type} == 1 || $_ -> {id_voc})? $values :
						undef,
					empty  => ' ',
				}} @{$data -> {ext_fields}},
			),
			
			{
				type  => 'hgroup',
				label => 'Arrivé à',
				off   => $data -> {prestation} -> {type} -> {is_anonymous},
				
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
				off   => $data -> {prestation} -> {type} -> {is_anonymous},
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
	
	$title_1 .= " pour $data->{user}->{label}";
	
	return
			
		draw_toolbar (
					{
						keep_params => ['type'],
					},
					{
						type         => 'button',
						icon		 => 'cancel',
						label        => 'retour (Echap)',
						hotkey       => {code => Esc},
						href         =>
							$_REQUEST {id_inscription_to_clone} ? esc_href () : "/?type=prestations&week=$_REQUEST{_week}&year=$_REQUEST{_year}&id_site=$_REQUEST{id_site}&aliens=$_REQUEST{aliens}&id_prestation_type=$_REQUEST{id_prestation_type}",
					},
					{
						type         => 'input_select',
						name         => 'id_user',
						values       => $data -> {users},
						off          => $_REQUEST {id_inscription_to_clone},
					},
					$data -> {prevnext} -> {-1},
					{
						type         => 'input_date',
#						label		 => 'pour',
						name         => 'dt',
						no_read_only => 1,
						off          => $_REQUEST {id_inscription_to_clone},
					},		
					$data -> {prevnext} -> {1},
					{
						type         => 'input_select',
						name         => 'id_day_period',
						values       => $data -> {day_periods},
						off          => $_REQUEST {id_inscription_to_clone},
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

				if ($i -> {fake} == 0 && !(
				
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
				
					target => $_REQUEST {id_inscription_to_clone} ? 'invisible' : undef,
				
					href  =>

						$data -> {prestation_1} -> {read_only} || (
							$i -> {fake} && (
								0
								|| !$data -> {prestation_1} -> {present_users}
								|| $data -> {week_status_type} -> {id} != 2
							)
						) ? undef :

						$_REQUEST {id_inscription_to_clone} ? "/?type=inscriptions&id=$$i{id}&action=copy_from&_id_inscription_to_clone=$_REQUEST{id_inscription_to_clone}" :

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
						label => $i -> {recu_par},
#						off   => !$i -> {hour},
					},
					map {
						{
							label   => $i -> {'field_' . $_ -> {id_ext_field}},
							href    => $_ -> {id_field_type} == 6 ? "/?type=ext_field_values&action=download&id=" . $i -> {'field_' . $_ -> {id_ext_field} . '_id'} : undef,
							target  => $_ -> {id_field_type} == 6 ? 'invisible' : undef,
							max_len => 1000,
						},
					} @{$data -> {prestation_1} -> {ext_fields}},
				])

			},

			$data -> {prestation_1} -> {inscriptions},

			{
				
				title => {label => $title_1},
				
				off => $_REQUEST {id_day_period} == 2,
				
				lpt => 1,

				top_toolbar => draw_toolbar ( {},
									
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
					{
						icon     => 'create',
						href     => $data -> {prestation_1} -> {clone_href},
						label    => 'Dupliquer...',
						keep_esc => 0,
						off      =>
							$_USER -> {role} ne 'admin' ||
							$data -> {user} -> {id_organisation} != $_USER -> {id_organisation}
					},
				
				)
				
		.

qq {
	<table cellspacing=0 cellpadding=0 width="100%"><tr><td class=bgr8><table cellspacing=1 cellpadding=0 width="100%" id="scrollable_table">
}

		. (!$data -> {prestation_1} -> {note} ? '' : '<tr>' . draw_text_cell ({
			label   => '<b>Note:</b> ' . $data -> {prestation_1} -> {note},
			max_len => 10000,
			no_nobr => 1,
		}))
		
		. (!$data -> {prestation_1} -> {file_name} ? '' : '<tr>' . draw_text_cell ({
			label   => '<b>Pièce jointe :</b> ' . $data -> {prestation_1} -> {file_name},
			href    => "/?type=prestations&action=download&id=$data->{prestation_1}->{id}",
			target  => 'invisible',
			max_len => 10000,
			no_nobr => 1,
		}))

		.
		
qq {
	</table></td></tr></table>
}

				,
				
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

				if ($i -> {fake} == 0 && !(
				
					$c_est_mon_organisation or ($i -> {id_organisation} == $_USER -> {id_organisation} or !$i -> {id_organisation})
				
				)) {
					

					return draw_cells ({}, [
						$i -> {label},
						{
							label   => 'Réservé',
							colspan => 3 + @{$data -> {prestation_2} -> {ext_fields}},
							max_len => 10000,
							no_nobr => 1,
						},
					]);
					
				}

			    my $mark_href = {href => '/?type=inscriptions&action=mark&id=' . $i -> {id}};
			    check_href ($mark_href);

				draw_cells ({

					target => $_REQUEST {id_inscription_to_clone} ? 'invisible' : undef,

					href  =>
						$data -> {prestation_2} -> {read_only} || (
							$i -> {fake} && (
								!$data -> {prestation_2} -> {present_users}
								|| $data -> {week_status_type} -> {id} != 2
							)
						) ? undef :
						
						$_REQUEST {id_inscription_to_clone} ? "/?type=inscriptions&id=$$i{id}&action=copy_from&_id_inscription_to_clone=$_REQUEST{id_inscription_to_clone}" :
						
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
						label => $i -> {recu_par},
#						off   => !$i -> {hour},
					},

					map {
						{
							label  => $i -> {'field_' . $_ -> {id_ext_field}},
							href   => $_ -> {id_field_type} == 6 ? "/?type=ext_field_values&action=download&id=" . $i -> {'field_' . $_ -> {id_ext_field} . '_id'} : undef,
							target => $_ -> {id_field_type} == 6 ? 'invisible' : undef,
							max_len => 1000,
						},
					} @{$data -> {prestation_2} -> {ext_fields}},

				])

			},

			$data -> {prestation_2} -> {inscriptions},

			{
				
				title => {label => "$_REQUEST{_day_name} $_REQUEST{dt}" . ' après-midi : ' . ($data -> {prestation_2} -> {type} -> {label} || 'libre') . " pour $data->{user}->{label}"},
				
				off => $data -> {prestation_1} -> {id} == $data -> {prestation_2} -> {id} || $_REQUEST {id_day_period} == 1,

				lpt => 1,
				
				top_toolbar => draw_toolbar ({},
				
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
					{
						icon     => 'create',
						href     => $data -> {prestation_2} -> {clone_href},
						label    => 'Dupliquer...',
						keep_esc => 0,
						off      =>
							$_USER -> {role} ne 'admin' ||
							$data -> {user} -> {id_organisation} != $_USER -> {id_organisation}
					},
				
				)
				
				
		.

qq {
	<table cellspacing=0 cellpadding=0 width="100%"><tr><td class=bgr8><table cellspacing=1 cellpadding=0 width="100%" id="scrollable_table">
}

		. (!$data -> {prestation_2} -> {note} ? '' : '<tr>' . draw_text_cell ({
			label   => '<b>Note:</b> ' . $data -> {prestation_2} -> {note},
			max_len => 10000,
			no_nobr => 1,
		}))
		
		. (!$data -> {prestation_2} -> {file_name} ? '' : '<tr>' . draw_text_cell ({
			label   => '<b>Pièce jointe :</b> ' . $data -> {prestation_2} -> {file_name},
			href    => "/?type=prestations&action=download&id=$data->{prestation_2}->{id}",
			target  => 'invisible',
			max_len => 10000,
			no_nobr => 1,
		}))

		.
		
qq {
	</table></td></tr></table>
}

			}
			
		)
		
		.
		
		iframe_alerts ()
		
		;

}

1;
