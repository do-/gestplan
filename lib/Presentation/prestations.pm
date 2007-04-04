################################################################################

sub draw_item_of_prestations {

	my ($data) = @_;

	draw_form ({
	
		right_buttons => [ del ($data) ],
		
	}, $data,
		[
			{
				name   => 'id_user',
				label  => 'Conseiller',
				type   => 'select',
				values => $data -> {users},
				read_only => $_USER -> {role} ne 'admin',
				add_hidden => 1,
			},
			{
				name   => 'id_users',
				label  => 'Co-animateurs',
				type   => 'checkboxes',
				height => 150,
				values => $data -> {users},
				cols   => 3,
				read_only =>
					$_USER -> {role} ne 'admin'
					&& $data -> {prestation_type} -> {is_placeable_by_conseiller} != 1
					&& !(
						$data -> {prestation_type} -> {is_placeable_by_conseiller} == 2
						&& $data -> {prestation_type} -> {ids_users} =~ /\,$$_USER{id}\,/
					)
					,
				off    => $data -> {prestation_type} -> {id_people_number} == 1,
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
			
#			off   => 0 == @{$data -> {ids_rooms}} || !$_REQUEST {__read_only},
			off   => !$_REQUEST {__read_only},
			
			name  => 'rtf',
			
			top_toolbar => [{},
			
				{
					label => 'R�server',
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
	
	my $off_period_divs = <<EOJS;
		<script>
			function coord (row, col, what) {
				var tbody = document.getElementById ('scrollable_table').tBodies(0);
				var _row = tbody.rows [row];
				
				if (!_row) {
//					alert ('coord: row ' + row + ' not found');
					return 0;
				}

				var _cell = _row.cells [col];

				if (!_cell) {
//					alert ('coord: col ' +  col + ' in row ' + row + ' not found');
					return 0;
				}
				
				return _cell ['offset' + what];
				
			}
		</script>
EOJS
	
	my $shift = $data -> {menu} ? 128 : 111;
	
	foreach my $off_period (@{$data -> {off_periods}}) {
	
		$off_period_divs .= <<EOH;
			<div
				onMouseOver="this.style.display='none'"
				onMouseOut="this.style.display='block'"
				style="
				border:solid black 1px;
				position:absolute;
				background-image: url(/i/stripes.gif);
				z-index:1;
				display:expression(document.getElementById ('scrollable_table').offsetParent.scrollTop > 45 ? 'none' : 'block');
				top:expression($shift + 	coord ($$off_period{row}, $$off_period{col_start}, 'Top') - document.getElementById ('scrollable_table').offsetParent.scrollTop);
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

	return
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	    draw_form (
		
			{
				
				menu => $data -> {menu},
				
				bottom_toolbar => ' ',

				max_len => 255,

			},
			
			
			{
				path => [{
					name => "Planning g�n�ral de la semaine $_REQUEST{week} du " .
					$data -> {days} -> [0] -> {date} -> [2] .
					' ' .
					($data -> {days} -> [0] -> {date} -> [1] == $data -> {days} -> [-1] -> {date} -> [1] ? '' : $month_names_1 [$data -> {days} -> [0] -> {date} -> [1]]) .
					' � ' .
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
		    	[
		    		map {{
						label => ($_ -> {id} % 2 ? 'Apr�s-midi' : 'Matin'),
#						href => {type => 'inscriptions_par_jour', dt_from => $_ -> {fr_dt}, dt_to => $i -> {fr_dt}},
					}} @{$data -> {days}},
				],
		
			],
			
			sub {
				
				$i -> {id} or return draw_cells ({}, [
					{
						label => $i -> {label},
						colspan => 11,
						attributes => {align => 'center'},
						bold => 1,
					},
				]);
				

				draw_cells ({
				}, [

					{
						label      => $i -> {label},
						href       => $i -> {id} < 0 ? undef : {
							type => 'inscriptions_par_jour',
							dt_from => $data -> {days} -> [0] -> {fr_dt},
							dt_to => $data -> {days} -> [-1] -> {fr_dt},
							id_user => $i -> {id}
						},
					},

					(map {{
					
						hidden => $_ -> {by_user} -> {$i -> {id}} -> {is_hidden},
						
						label => $_ -> {by_user} -> {$i -> {id}} -> {label},
						
						title =>
							$_ -> {by_user} -> {$i -> {id}} -> {note} ?	$_ -> {by_user} -> {$i -> {id}} -> {note} :
							$_ -> {by_user} -> {$i -> {id}} -> {inscriptions} ?	$_ -> {by_user} -> {$i -> {id}} -> {inscriptions} :
							"$$_{label} " . $data -> {day_periods} -> [$_ -> {id} % 2] -> {label} . " pour $$i{label}",
						
						href =>
							!$_ -> {by_user} -> {$i -> {id}} -> {label} ? undef :
							$i -> {id} < 0 ? undef :
							"/?type=inscriptions&id_user=$$i{id}&dt=$$_{fr_dt}&id_site=$_REQUEST{id_site}&id_day_period=" . $_ -> {by_user} -> {$i -> {id}} -> {half_start},
						
						attributes => {
							bgcolor => $_ -> {by_user} -> {$i -> {id}} -> {bgcolor},
							align => 'center',
							colspan => $_ -> {by_user} -> {$i -> {id}} -> {rowspan},							
							(
								($_USER -> {role} eq 'admin' && !$i -> {is_alien}) || (
									$_USER -> {role} eq 'conseiller' &&
									
									(
										
										$_ -> {by_user} -> {$i -> {id}} -> {ids_users} =~ m{\,$$_USER{id}\,} ||
									

                                    	(

											!$_ -> {by_user} -> {$i -> {id}} -> {label} &&
											
											(
												$_USER -> {can_dblclick_others_empty} || $_USER -> {id} == $i -> {id}
											)
										
										)
										
										
										
										||

									
									($i -> {id} == $_USER -> {id} &&
									(
										$_ -> {by_user} -> {$i -> {id}} -> {is_placeable_by_conseiller} == 1 ||
										!$_ -> {by_user} -> {$i -> {id}} -> {label}
									)))
								) || (
									$_USER -> {role} eq 'accueil' &&
									$i -> {id} == $_USER -> {id}
								)
								
							) ? (onDblClick =>
#								$i -> {id} < 0 ? '' :
								($data -> {week_status_type} -> {id} != 2 && ($data -> {week_status_type} -> {id} != 1 || $_USER -> {role} ne 'admin')) ? '' :
								$_ -> {by_user} -> {$i -> {id}} -> {id} < 0 ? '' :
								"nope(\"$$_{create_href}&id_user=$$i{id}\", \"invisible\")"
							) : (),
						},
						
					}} @{$data -> {days}}),

					
				])

			},

			$data -> {users},

			{
				
#				title => {
#					label => "Planning g�n�ral de la semaine $_REQUEST{week} du " .
#					$data -> {days} -> [0] -> {date} -> [2] .
#					' ' .
#					($data -> {days} -> [0] -> {date} -> [1] == $data -> {days} -> [-1] -> {date} -> [1] ? '' : $month_names_1 [$data -> {days} -> [0] -> {date} -> [1]]) .
#					' � ' .
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

				top_toolbar => [{
					keep_params => ['type', 'year', 'id_site'],
				},

					{
						icon    => 'left',
						label   => 'Pr�c�dente',
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
						confirm => $data -> {week_status_type} -> {switch} -> {label} . ' le planning pour cette semaine, vous �tes s�r ?',
						href    => {action => 'switch_status', id_week_status_type => $data -> {week_status_type} -> {switch} -> {id}},
						off     => $_USER -> {role} ne 'admin',
					},
			
					{
						icon    => 'create',
						label   => 'Mod�les',
						href    => {action => 'add_models'},
						off     =>
							$data -> {have_models} ||
							$_USER -> {role} ne 'admin' ||
							$data -> {week_status_type} -> {id} != 1,
					},
					
					{
						icon    => 'delete',
						label   => 'Effacer',
						href    => {action => 'clear'},
						confirm => "Etes-vous s�r qu'il soit n�cessaire de supprimer TOUTES les prestations de cette semaine?",
						off     => $_USER -> {role} ne 'admin' || $data -> {week_status_type} -> {id} != 1,
					},

				],

			}
			
		)
		
		.
		
		$off_period_divs

		.
		
		iframe_alerts ()
		
		;

}

1;
