################################################################################

sub draw_item_of_prestations {

	my ($data) = @_;
	
	$_REQUEST {__read_only} or $_REQUEST {__on_load} .= <<EOH;
	
		var id_users_0 = document.forms['form'].elements['_id_users_0'];
		
		if (id_users_0) {
	
			id_users_0.onclick = function () {
				
				var elems = document.forms['form'].elements;
				
				if (!elems ['_id_users_0'].checked) return;
				
				for (var ix=0; ix < elems.length; ix ++) {	
				
				    var elem = elems [ix];
				    if (elem.type != 'checkbox')    continue;
				    if (elem.name == '_id_users_0') continue;
				    if (elem.checked)               continue;
				    elem.checked = true;
				
				}
	
			}
		
		}

EOH

	draw_form ({
	
		right_buttons => [ del ($data) ],
		
	}, $data,
		[
			{
				name   => 'id_user',
				label  => 'Utilisateur',
				type   => 'select',
				values => $data -> {users},
				read_only => $_USER -> {role} ne 'admin',
				add_hidden => 1,
				off    => $data -> {id_user} <= 0,
			},
			{
				name   => 'id_users',
				label  => 'Co-animateurs',
				type   => 'checkboxes',
				height => 150,
				values => [{id => 0, label => '<b><u>Tous</u></b>'}, @{$data -> {users}}],
				cols   => 3,
				read_only =>
					$_USER -> {role} ne 'admin'
					&& $data -> {prestation_type} -> {is_placeable_by_conseiller} != 1
					&& !(
						$data -> {prestation_type} -> {is_placeable_by_conseiller} == 2
						&& $data -> {prestation_type} -> {ids_users} =~ /\,$$_USER{id}\,/
					)
					,
				off    =>
					$data -> {prestation_type} -> {id_people_number} == 1
					|| $data -> {id_user} <= 0
					,
			},
			[
				{
					type   => 'hgroup',
					label  => 'Du',
					items  => [
					
						{
							type => 'date',
							name => 'dt_start',
							no_read_only => 1,
							read_only => 0 < @{$data -> {inscriptions}},
							add_hidden => 1,
						},
						{
							type   => 'select',
							name   => 'half_start',
							values => $data -> {day_periods},
							read_only => 0 < @{$data -> {inscriptions}},
							add_hidden => 1,
						},
										
					],
				},
				{
					type   => 'hgroup',
					label  => "au",
					items  => [
					
						{
							type => 'date',
							name => 'dt_finish',
							no_read_only => 1,
							read_only => 0 < @{$data -> {inscriptions}},
							add_hidden => 1,
						},
						{
							type  => 'select',
							name  => 'half_finish',
							values => $data -> {day_periods},
							read_only => 0 < @{$data -> {inscriptions}},
							add_hidden => 1,
						},
										
					],
				},
			],
			{
				name       => 'id_prestation_type',
				label      => 'Type de prestation',
				type       => 'select',
				values     => $data -> {prestation_types},
				empty      => '[Veuillez choisir le type]',
				other      => $_USER -> {role} eq 'admin' ? '/?type=prestation_types' : undef,
				read_only  => $data -> {id_prestation_type},
				add_hidden => 1,
			},
			{
				type  => 'text',
				label => 'Note',
				name  => 'note',
				cols  => 80,
				rows  => 3,
			},
		],
	)
	
	.
	
	draw_table (

		sub {
		
			__d ($i, 'dt_start', 'dt_finish');
		
			draw_cells ({
					href => "/?type=prestations_rooms&id=$$i{id}",
				}, [
				$i -> {label},
				$i -> {dt_start}  . ' ' . $i -> {start_label},
				$i -> {dt_finish} . ' ' . $i -> {finish_label},
			])
		
		},
		
		$data -> {prestations_rooms},
		
		{
			
			title => {label => 'Salles'},
			
			off   => !$_REQUEST {__read_only},
			
			name  => 'rtf',
			
			top_toolbar => [{},
			
				{
					label => 'Réserver',
					icon  => 'create',
					href  => "/?type=prestations_rooms&action=create&id_prestation=$$data{id}&dt_start=$$data{_dt_start}&half_start=$$data{half_start}&dt_finish=$$data{_dt_finish}&half_finish=$$data{half_finish}",
				},
			
			],
			
		},

	)
	
	.
	
	draw_table (

		sub {
		
			draw_cells ({}, [
				$i -> {label},
				$i -> {nom},
				$i -> {prenom},
			])
		
		},
		
		$data -> {inscriptions},
		
		{
			title => {label => 'Inscriptions'},
			off   => 0 == @{$data -> {inscriptions}},
			name  => 'tf',
		},

	)
	
	;

}

################################################################################

sub draw_prestations {
	
	my ($data) = @_;
	
	my $shift = $data -> {menu} ? 128 : 111;

	my $off_period_divs = <<EOJS;
		<script>
			
			function coord (row, col, what) {


				var tbody = document.getElementById ('scrollable_table').tBodies(0);
				var _row = tbody.rows [row];
			
				if (!_row) {
//					alert ('coord ('+row+', ' + col +', '+what+') : no row');
					return 0;
				}
			
				var _cell = _row.cells [col];

				if (!_cell) {
//					alert ('coord ('+row+', ' + col +', '+what+') : no cell');
					return 0;
				}
			
				return _cell ['offset' + what];			

			}

			function coord_h (row, col, what) {
				var thead = document.getElementById ('scrollable_table').tHead;
				var _row = thead.rows [row];

				if (!_row) {
//					alert ('coord_h ('+row+', ' + col +', '+what+') : no row');
					return 0;
				}

				var _cell = _row.cells [col];

				if (!_cell) {
//					alert ('coord_h ('+row+', ' + col +', '+what+') : no cell');
					return 0;
				}

				return _cell ['offset' + what];			
			}
			
		</script>
EOJS


	my $from = -1;

	foreach my $i (1 .. @{$data -> {organisation} -> {days}}) {
				
				$off_period_divs .= <<EOH;
					<div
						style="
							border:0px;
							position:absolute;
							background: #485F70;
							left:expression(
								coord_h (0, $i, 'Left')
								- document.getElementById ('scrollable_table').offsetParent.scrollLeft
								- 1
							);
							height:44;
							top:expression(document.getElementById ('scrollable_table').offsetParent.scrollTop);
							width:2;
					"
					><img src="/i/0.gif" width=1 height=1></div>
EOH
	}

	push @{$data -> {users}}, {};

	for (my $j = 0; $j < @{$data -> {users}}; $j++) {
	
		my $user = $data -> {users} -> [$j];
		
		next if $user -> {id};
		
		if ($from > -1) {
						
			my $top     = 44 + 22 * $from;
			my $height  = 22 * ($j - $from);
			my $height1 = $height + 1;
			
			$data -> {users} -> [$from] -> {span} = $j - $from;

			foreach my $i (1 .. @{$data -> {organisation} -> {days}}) {
				
				$off_period_divs .= <<EOH;
					<div
						style="
							border:0px;
							position:absolute;
							background-color: #485F70;
							left:expression(
								coord_h (0, $i, 'Left')
								- document.getElementById ('scrollable_table').offsetParent.scrollLeft
								- 1
							);
							height:$height;
							top:$top;
							width:2;
					"
					><img src="/i/0.gif" width=1 height=1></div>
EOH

				my $day = $data -> {days} -> [2 * $i - 1];

			}

		}
			
		$from = $j + 1;
		
	}
	
	pop @{$data -> {users}};

	foreach my $off_period (@{$data -> {off_periods}}) {
	
		$off_period_divs .= <<EOH;
			<div
				onMouseOver="this.style.display='none'"
				onMouseOut="this.style.display='block'"
				style="
				border:solid black 1px;
				position:absolute;
				background-image: url(/i/stripes.gif);
				display:expression(document.getElementById ('scrollable_table').offsetParent.scrollTop > coord ($$off_period{row}, $$off_period{col_start}, 'Top') - 45 ? 'none' : 'block');
				top:expression(coord ($$off_period{row}, $$off_period{col_start}, 'Top'));
				left:expression( 	coord ($$off_period{row}, $$off_period{col_start}, 'Left') - document.getElementById ('scrollable_table').offsetParent.scrollLeft);				
				height:expression(	coord ($$off_period{row}, $$off_period{col_start}, 'Height'));
				width:expression(
									coord ($$off_period{row}, $$off_period{col_finish}, 'Width') -
									coord ($$off_period{row}, $$off_period{col_start},  'Left') +
									coord ($$off_period{row}, $$off_period{col_finish}, 'Left')
				);				
			"
			>
				&nbsp;
			</div>
EOH
		
	}

	
	
	
	
	
	
	
	
	
	
		my @h2 = ();
		
		foreach my $day (@{$data -> {days}}) {
		
			my $holyday = $data -> {holydays} -> {$day -> {iso_dt}};
			
			if ($holyday) {
			
				next if $day -> {id} % 2;
				
				push @h2, {
					label => $holyday -> {label},
					colspan => 2,
				};
			
			}
			else {

				push @h2, {
					label => ($day -> {id} % 2 ? 'Après-midi' : 'Matin'),
				};

			}
							
		}
	
	
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
					name => "Planning activités de la semaine $_REQUEST{week} du " .
					$data -> {days} -> [0] -> {date} -> [2] .
					' ' .
					($data -> {days} -> [0] -> {date} -> [1] == $data -> {days} -> [-1] -> {date} -> [1] ? '' : $month_names_1 [$data -> {days} -> [0] -> {date} -> [1]]) .
					' à ' .
					$data -> {days} -> [-1] -> {date} -> [2] .
					' ' .
					$month_names_1 [$data -> {days} -> [-1] -> {date} -> [1]] .
					' ' .
					$data -> {days} -> [-1] -> {date} -> [0] .
					': ' .
					$data -> {week_status_type} -> {label},
					,					
				}],
			},
		
			[],
		)
		
		.	

		draw_table (
		
			[
		    
			    	[
					{label => 'Nom', rowspan => 2},
		    	
			    		map {{
						label => $_ -> {label},
						colspan => 2,
						hidden => ($_ -> {id} % 2),
						href => $_REQUEST {xls} ? undef : {type => 'inscriptions_par_jour', dt_from => $_ -> {fr_dt}, dt_to => $_ -> {fr_dt}},
					}} @{$data -> {days}},
			
				],
				
				\@h2,
		    		
			],

			sub {
				
				$i -> {id} or return draw_cells ({}, [
					{
						label => $i -> {label},
						colspan => 1 + 2 * @{$data -> {organisation} -> {days}},
						attributes => {align => 'center'},
						bold => 1,
					},
				]);
				
				my @cells = (
					{
						label      => $i -> {label},
						href       => $i -> {id} < 0 ? undef : {
							type => 'inscriptions_par_jour',
							dt_from => $data -> {days} -> [0] -> {fr_dt},
							dt_to => $data -> {days} -> [-1] -> {fr_dt},
							id_user => $i -> {id}
						},
					},
				);
								
				foreach my $day (@{$data -> {days}}) {

					my $p = $day -> {by_user} -> {$i -> {id}};
					
					if ($data -> {holydays} -> {$day -> {iso_dt}}) {
	
						next if !$i -> {span} || $day -> {id} % 2;
						
						push @cells, {
							colspan => 2,
							rowspan => $i -> {span},
							attributes => {
								background => '/i/reptile007.jpg',
							},
						};
						
						next;
	
					}
					
					my $cell = {
						hidden  => $p -> {is_hidden},
						label   => $p -> {label},
						max_len => 1000000,
						status  => $p -> {status},
						title   => $p -> {note} || $p -> {inscriptions} || "$$day{label} " . $data -> {day_periods} -> [$day -> {id} % 2] -> {label} . " pour $$i{label}",
					};
					
					$cell -> {href} = "/?type=inscriptions&id_user=$$i{id}&dt=$$day{fr_dt}&id_site=$_REQUEST{id_site}&aliens=$_REQUEST{aliens}&id_day_period=" . $p -> {half_start} if $p -> {label} && $i -> {id} >= 0 && !$p -> {no_href};
					
					$cell -> {attributes} = {
						bgcolor => ($p -> {bgcolor} ||= 'white'),
						align   => 'center',
						colspan => $p -> {rowspan},							
					};
					
					if (
						(
							
							(
								$_USER -> {role} eq 'admin'
								&& !$i -> {is_alien}
							)
							
							|| (
								
								$_USER -> {role} eq 'conseiller'
								
								&& (
									
									$p -> {ids_users} =~ m{\,$$_USER{id}\,}

                            						|| (

										!$p -> {label}
										
										&& (
											$_USER -> {can_dblclick_others_empty}
											|| $_USER -> {id} == $i -> {id}
										)
									
									)
									
									|| (
										
										$i -> {id} == $_USER -> {id}
										
										&& (
											$p -> {is_placeable_by_conseiller} == 1
											|| !$p -> {label}
										)
									)
								)
							)
							
							|| (
								$_USER -> {role} eq 'accueil' &&
								$i -> {id} == $_USER -> {id}
							)
							
						)
						
						&& !(
						
							$data -> {week_status_type} -> {id} != 2
							
							&& (
								$data -> {week_status_type} -> {id} != 1
								|| $_USER -> {role} ne 'admin'
							)
							
						)
						
						&& !(
							$p -> {id} < 0
						)

						&& !(
							
							!$p -> {label}
										
							&& $i -> {id} < 0
							
							&& !$_USER -> {can_dblclick_others_empty}
							
						)
					
					) {
						$cell -> {attributes} -> {onDblClick} = "nope(\"$$day{create_href}&id_user=$$i{id}\", \"invisible\")";
					}
					
					push @cells, $cell;	
				
				}
				
				return draw_cells ({}, \@cells);

			},

			$data -> {users},

			{
				
#				title => {
#					label => "Planning activités de la semaine $_REQUEST{week} du " .
#					$data -> {days} -> [0] -> {date} -> [2] .
#					' ' .
#					($data -> {days} -> [0] -> {date} -> [1] == $data -> {days} -> [-1] -> {date} -> [1] ? '' : $month_names_1 [$data -> {days} -> [0] -> {date} -> [1]]) .
#					' à ' .
#					$data -> {days} -> [-1] -> {date} -> [2] .
#					' ' .
#					$month_names_1 [$data -> {days} -> [-1] -> {date} -> [1]] .
#					' ' .
#					$data -> {days} -> [-1] -> {date} -> [0] .
#					': ' .
#					$data -> {week_status_type} -> {label},
#					,
#					
#				},
				
				lpt => 1,
				
				dotdot => $off_period_divs,
				
#				no_scroll => 1,

				top_toolbar => [{
					keep_params => ['type', 'year', 'id_site'],
				},

					{
						icon    => 'left',
						label   => 'Précédente',
						href    => {week => $data -> {prev} -> [0], year => $data -> {prev} -> [1]},
					},
					
					{
						type    => 'input_text',
						size    => 2,
						name    => 'week',
						label   => 'Semaine',
						keep_params => [],
					},
					
					{
						icon    => 'right',
						label   => 'Suivante',
						href    => {week => $data -> {next} -> [0], year => $data -> {next} -> [1]},
					},

					{
						type   => 'input_select',
						label  => 'Prestation',
						show_label => 1,
						name   => 'id_prestation_type',
						values => $data -> {prestation_types},
						empty  => '',
						off    => $_USER -> {role} eq 'accueil',
					},
					
					{
						icon    => $data -> {week_status_type} -> {switch} -> {icon},
						label   => $data -> {week_status_type} -> {switch} -> {label},
						confirm => $data -> {week_status_type} -> {switch} -> {label} . ' le planning pour cette semaine, vous êtes sûr ?',
						href    => {action => 'switch_status', id_week_status_type => $data -> {week_status_type} -> {switch} -> {id}},
						off     => $_USER -> {role} ne 'admin',
					},
			
					{
						icon    => 'create',
						label   => 'Modèles',
						href    => {action => 'add_models'},
						target  => 'invisible',
						off     =>
							$data -> {have_models} ||
							$_USER -> {role} ne 'admin' ||
							$data -> {week_status_type} -> {id} != 1,
					},
					
					{
						icon    => 'delete',
						label   => 'Effacer',
						href    => {action => 'clear'},
						confirm => "Etes-vous sûr qu'il soit nécessaire de supprimer TOUTES les prestations de cette semaine?",
						off     => $_USER -> {role} ne 'admin' || $data -> {week_status_type} -> {id} != 1,
					},

				],

			}
			
		)
		
		.
		
		iframe_alerts ()
		
		;

}

1;
