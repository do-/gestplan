
################################################################################

sub draw_prestations_month {

	my ($data) = @_;

	my $shift = $data -> {menu} ? 106 : 66;
	
	my $h_create = {href => "/?type=prestations&id_prestation_type=$_REQUEST{id_prestation_type}&id_site=$_REQUEST{id_site}"};
	
	check_href ($h_create);	

	$h_create -> {href} .= $_REQUEST {id_prestation_to_clone} ? "&action=clone&id=$_REQUEST{id_prestation_to_clone}" : "&action=create";
	
	js qq {
	
		var __st;
		var __stop;
		var __stopsl;
		var __stopst;
		var __off = [];
		var u2r = {};
		var sem = {};
		
			function c (dt, half, id_user) {
			
				var id = dt + '-' + half + '-' + id_user;
				
				if (sem [id]) return;
				
				sem [id] = true;				

				\$.getScript ('$h_create->{href}&id_user=' + id_user
					+ '&__last_scrollable_table_row='    + u2r [id_user]
					+ '&dt_start='    + dt
					+ '&half_start='  + half
					+ '&dt_finish='   + dt
					+ '&half_finish=' + half
					+ '&_salt='       + Math.random ()
				, function () {
					sem [id] = setTimeout (function () {
					    clearTimeout (sem [id]);
					    sem [id] = false;
					}, 100);
				});
				
				return blockEvent ();
			
			}
		
			function set_cell (o) {
			
				var col = 2 * (o.dow - 1) + o.half;
				
				for (var i = 0; i < o.ids_users.length; i ++) {
				
					var id = o.dt_start + '-' + o.half + '-' + o.ids_users [i];

					var c = document.getElementById (id);
					
					if (!c) continue;

					c.style.backgroundColor = o.color;

					if (o.no_href) {

						\$(c).text (o.label_short);

					}
					else {
					
						var href = '$_REQUEST{__uri}?type=inscriptions&month=$_REQUEST{month}&sid=$_REQUEST{sid}&id_user=' + o.id_user
							+ '&__last_query_string='         + $_REQUEST{__last_query_string}
							+ '&id_site='                     + $_REQUEST{id_site}
							+ '&id_prestation_type='          + o.id_prestation_type
							+ '&__last_scrollable_table_row=' + o.__last_scrollable_table_row
							+ '&id_day_period='               + o.half
							+ '&dt='                          + o.dt_start.substring (8, 10)+ '/' + o.dt_start.substring (5, 7)+ '/' + o.dt_start.substring (0, 4)
							+ '&_salt='                       + Math.random ()
						;

						\$(c).html ('<a onFocus="blur()" class=row-cell href="' + href + '">' + o.label_short + '</a>');
						
						tableSlider.cell_off ();
					
					}
					

				}

			}
						
			function coord (row, col, what) {

            	if (!__st) return 0;

				var _row = __st.rows [row];
			
				if (!_row) {
					return 0;
				}
			
				var _cell = _row.cells [col];

				if (!_cell) {
					return 0;
				}
			
				return _cell ['offset' + what];			

			}

			function coord_h (col, what) {
			
            	if (!__st) return 0;
			
				var thead = __st.tHead;
				var _row = thead.rows [1];
				if (!_row) return 0;
				var _cell = _row.cells [col];
				if (!_cell) return 0;
				return _cell ['offset' + what];			
			}

			function draw_borders () {
			
				if (!__st) return;
				
				rows = __st.rows;

				for (var i = 0; i < rows.length; i ++) {
	
					var r = rows [i];
	
					var cs = 0;
					
					var cells = r.cells;
					
					for (var j = cells.length - 1; j > -1 ; j --) {
					
						var c = cells [j];
						
						cs += c.colSpan;
						
						if (cs % 2 == 1) continue;
						
						var ps = c.previousSibling;
						
						if (ps) ps.style.borderRight = 'solid #505080 2px';
					
					}
				
				}

			}

			function redraw_off_divs () {

				if (!__st) return;
				__stop   = __st.offsetParent;
				__stopsl = __stop.scrollLeft;
				__stopst = __stop.scrollTop;
				
				var delta_top = 46;
				
				if (!browser_is_msie) {
					delta_top = $shift + __stopst + __st.rows[0].offsetHeight + __st.rows[1].offsetHeight - __the_div[0].scrollTop;
				}
	
			    for (var i = 0; i < __off.length; i ++) {
			
			    	o = __off [i];
			    	s = document.getElementById (o.id).style;
					s.top    = coord   (o.row, 0, 'Top') + delta_top;
					s.left   = coord_h (o.col_start - 1, 'Left') - __stopsl - 1 - 1 * (1 - browser_is_msie);
					s.height = coord   (o.row, 0, 'Height') - 1 * (1 - browser_is_msie);
					s.width  = (
							coord_h (o.col_finish - 1, 'Width') -
							coord_h (o.col_start  - 1, 'Left') +
							coord_h (o.col_finish - 1, 'Left')
					);				
			
					if (browser_is_msie) {
//						s.display      = __stopst > coord (o.row, o.col_start, 'Top') - 45 ? 'none' : 'block';
					}
					else {
						s.display      = __the_div[0].scrollTop > coord (o.row, o.col_start, 'Top') + 45 ? 'none' : 'block';
					}

				}

			}
			
			var __off_div_timer;
			var __the_div;

	};
	
	j q {

			__st = document.getElementById (scrollable_table_ids [0]);
			
            draw_borders ();

			__off_div_timer = setTimeout (redraw_off_divs, 100);
			
			$(window).resize (function () {
			
				if (__off_div_timer) clearTimeout (__off_div_timer);

				__off_div_timer = setTimeout (redraw_off_divs, 100);
				
			});
			
			if (!browser_is_msie && __st) {
				__stop = __st.offsetParent;
				__the_div = $('div.table-container');
				__the_div.scroll (redraw_off_divs);
			}

	};
	
	my $off_period_divs = '';

	my $from = -1;

	push @{$data -> {users}}, {};
		
	for (my $j = 0; $j < @{$data -> {users}}; $j++) {
	
		my $user = $data -> {users} -> [$j];
		
		next if $user -> {id};
		
		if ($from > -1) {
									
			$data -> {users} -> [$from] -> {span} = $j - $from;

		}
			
		$from = $j + 1;
		
	}
	
	pop @{$data -> {users}};
		
	foreach my $off_period (@{$data -> {off_periods}}) {
	
		$off_period -> {id} = '' . $off_period;
		
		my $j = $_JSON -> encode ($off_period);
		
		js qq {__off.push ($j);};
	
		$off_period_divs .= <<EOH;
			<div
				id="$$off_period{id}"
				onMouseOver="this.style.display='none'"
				onMouseOut="this.style.display='block'"
				style="border:solid black 1px;position:absolute;background-image: url(/i/stripes.gif);"
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
					label => ($day -> {id} % 2 ? 'AM' : 'M'),
					attributes => {width => '8%'},
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
					$data -> {week_status_type} -> {label}
					. ($_REQUEST {id_inscription_to_clone} ? ' (Déplacement)' : '')
					. ($_REQUEST {id_prestation_to_clone}  ? " (Duplication $data->{prestation_to_clone}->{prestation_type}->{label_short} $data->{prestation_to_clone}->{user}->{label})" : '')
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
			
				my $colspan = 0;
							
				$i -> {id} or return draw_cells ({}, [
					{
						label => $i -> {label},
						colspan => 1 + 2 * $data -> {number_of_days},
						attributes => {align => 'center'},
						bold => 1,
					},
				]);
				
				js "u2r [$i->{id}] = $scrollable_row_id";

				my @cells = (
					{
						label      => $i -> {label},
						title      => $i -> {title} || $i -> {label},
						href       => $i -> {id} < 0 ? undef : {
							type => 'inscriptions_par_jour',
							dt_from => $data -> {days} -> [0] -> {fr_dt},
							dt_to => $data -> {days} -> [-1] -> {fr_dt},
							id_user => $i -> {id}
						},
					},
				);
				
				my $is_virgin = 1;
								
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
					
					$is_virgin = 0 if $p -> {label};
					
					$cell -> {href} = "/?type=inscriptions&month=$_REQUEST{month}&id_inscription_to_clone=$_REQUEST{id_inscription_to_clone}&id_user=$$i{id}&dt=$$day{fr_dt}&id_site=$_REQUEST{id_site}&aliens=$_REQUEST{aliens}&id_prestation_type=$_REQUEST{id_prestation_type}&id_day_period=" . $p -> {half_start} if $p -> {label} && $i -> {id} >= 0 && !$p -> {no_href};
					
					$cell -> {attributes} = {
						bgcolor => ($p -> {bgcolor} ||= 'white'),
						align   => 'center',
						colspan => $p -> {rowspan},	
						id => "$day->{iso_dt}-$day->{half}-$i->{id}",
					};

					push @cells, $cell;	
				
				}

                if ($_USER -> {role} eq 'admin' && $i -> {id} > 0) {

					push @cells, $is_virgin ? (map {{
						icon    => 'create',
						label   => "Appliquer la \"$_->{label}\" pour $i->{label}",
						confirm => "Appliquer la \"$_->{label}\" pour $i->{label}, vous êtes sûr?",
						href    => {
							action => 'add_models',
							id_user  => $i -> {id},
							id_model => $_ -> {id},
						},
					}} @{$data -> {models}}) :
					{
						icon    => 'delete',
						label   => "Effacer la semaine pour $i->{label}",
						confirm => "Effacer la semaine entière pour $i->{label}, vous êtes sûr?",
						href    => {
							action   => 'erase',
							id_user  => $i -> {id},
						}
					};	

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
					keep_params => ['type', 'year', 'id_site', 'id_prestation_to_clone', 'id_inscription_to_clone'],
				},

					{
						icon    => 'cancel',
						label   => 'retour (Echap)',
						href    => esc_href (),
						off     =>
							!$_REQUEST {id_inscription_to_clone}
							&& !$_REQUEST {id_prestation_to_clone}
						,
						hotkey  => {code => ESC},
					},

					{
						icon    => 'left',
						label   => 'Précédent',
						href    => {month => $data -> {prev} -> [1], year => $data -> {prev} -> [0]},
					},
					
					{
						type    => 'input_select',
						name    => 'month',
						values  => [map {{id => $_, label => $month_names [$_ - 1] . ' ' . $_REQUEST {year}}} (1 .. 12)]
					},
					
					{
						icon    => 'right',
						label   => 'Suivant',
						href    => {month => $data -> {next} -> [1], year => $data -> {next} -> [0]},
					},
					
					{
						icon    => 'options',
						label   => 'Liste',
						href       => $i -> {id} < 0 ? undef : {
							type => 'inscriptions_par_jour',
							dt_from => $data -> {days} -> [0] -> {fr_dt},
							dt_to => $data -> {days} -> [-1] -> {fr_dt},
						},
						off     =>
							$data -> {week_status_type} -> {id} == 1
						,
					},

					{
						type   => 'input_checkbox',
						label  => 'Seulement des personnes',
						name   => 'only_persons',
					},
					{
						type   => 'input_checkbox',
						label  => 'RH',
						name   => 'only_rh',
					},

				],

			}
			
		)
		
		.
		
		iframe_alerts ()
		
		;

}

1;
