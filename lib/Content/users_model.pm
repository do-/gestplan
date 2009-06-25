################################################################################

sub recalculate_users_model {

	send_refresh_messages ();

}

################################################################################

sub get_item_of_users_model {

	my $item = sql_select_hash ("users");
	
	$item -> {organisation} = sql_select_hash (organisations => $item -> {id_organisation});
	
	$item -> {organisation} -> {days} = [sort split /\,/, $item -> {organisation} -> {days}];
	
	__d ($item, 'dt_birth', 'dt_start', 'dt_finish');
	
	add_vocabularies ($item,
			
		prestation_types => {
			filter => "id_organisation = $$_USER{id_organisation}",
		},

	);

	$_REQUEST {__read_only} ||= !($_REQUEST {__edit} || $item -> {fake} > 0);	

	add_vocabularies ($item,
		
		'organisations',
		
		day_periods => {order => 'id'},
		
		roles => {
			order  => 'id',
			filter => $_USER -> {role} eq 'superadmin' ? 'id IN (1,4)' : 'id < 4',
		},
		
	);

	$item -> {path} = [
		{type => 'users', name => 'Utilisateurs'},
		{type => 'users', name => $item -> {label}, id => $item -> {id}},
	];
	
	$item -> {days} = [ map {(
		{
			day           => $_,
			label         => $day_names [$_ - 1],
			id_day_period => 1,
			rowspan       => 2,
			period_label  => $item -> {day_periods} -> [0] -> {label},
			id            => $_ . 1,
			by_mod2       => [{}, {}],
		},
		{
			day           => $_,
			id_day_period => 2,
			hidden        => 1,
			period_label  => $item -> {day_periods} -> [1] -> {label},
			id            => $_ . 2,
			by_mod2       => [{}, {}],
		},
	)} @{$item -> {organisation} -> {days}} ];
	
	my $ix = {};
	
	foreach my $day (@{$item -> {days}}) {
			
		$ix -> {$day -> {day}, $day -> {id_day_period}} = $day;
	
	}
	
	$item -> {prestation_models} = sql_select_all (<<EOS, $item -> {id}, {fake => 'prestation_models'});
		SELECT
			prestation_models.*
			, prestation_types.label
			, prestation_type_groups.color
		FROM
			prestation_models
			LEFT JOIN prestation_types ON prestation_models.id_prestation_type = prestation_types.id
			LEFT JOIN prestation_type_groups ON prestation_types.id_prestation_type_group = prestation_type_groups.id
		WHERE	
			id_user = ?
EOS
	
	my $default_color = sql_select_scalar ('SELECT color FROM prestation_type_groups WHERE id = -1');

	foreach my $prestation_model (@{$item -> {prestation_models}}) {
	
		my $day = $ix -> {$prestation_model -> {day_start}, $prestation_model -> {half_start}} -> {by_mod2} -> [$prestation_model -> {is_odd}];
		
		$day -> {id_prestation_model} = $prestation_model -> {id};
		$day -> {prestation_model_label} = $prestation_model -> {label};
		$day -> {color} = $prestation_model -> {color} || $default_color;
	
	}
	
	foreach my $day (@{$item -> {days}}) {
	
		foreach my $is_odd (0, 1) {
		
			my $i = $day -> {by_mod2} -> [$is_odd];

			$i -> {href} = $i -> {id_prestation_model} ?
				"/?type=prestation_models&id=$$i{id_prestation_model}&action=delete" :
				"/?type=prestation_models&action=create&id_prestation_type=$_REQUEST{id_prestation_type}&id_user=$$item{id}&day_start=$$day{day}&half_start=$$day{id_day_period}&is_odd=$is_odd";
	
			check_href ($i);

		}
	
	
	}

	return $item;	

}

1;
