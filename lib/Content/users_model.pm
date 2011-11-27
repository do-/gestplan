################################################################################

sub get_item_of_users_model {

	my $data = sql (users => $_REQUEST {id});
	
	$data -> {organisation} = sql_select_hash (organisations => $data -> {id_organisation});
	
	$data -> {organisation} -> {days} = [sort split /\,/, $data -> {organisation} -> {days}];
	
	__d ($data, 'dt_birth', 'dt_start', 'dt_finish');
	
	add_vocabularies ($data,
			
		prestation_types => {
			filter => "id_organisation = $$_USER{id_organisation}",
		},

	);

	$_REQUEST {__read_only} ||= !($_REQUEST {__edit} || $data -> {fake} > 0);	

	add_vocabularies ($data,
		
		'organisations',
		
		day_periods => {order => 'id'},
		
		roles => {
			order  => 'id',
			filter => $_USER -> {role} eq 'superadmin' ? 'id IN (1,4)' : 'id < 4',
		},
		
	);

	$data -> {path} = [
		{type => 'users', name => 'Utilisateurs'},
		{type => 'users', name => $data -> {label}, id => $data -> {id}},
	];
	
	$data -> {days} = [ map {(
		{
			day           => $_,
			label         => $day_names [$_ - 1],
			id_day_period => 1,
			rowspan       => 2,
			period_label  => $data -> {day_periods} -> [0] -> {label},
			id            => $_ . 1,
#			by_mod2       => [{}, {}],
		},
		{
			day           => $_,
			id_day_period => 2,
			hidden        => 1,
			period_label  => $data -> {day_periods} -> [1] -> {label},
			id            => $_ . 2,
#			by_mod2       => [{}, {}],
		},
	)} @{$data -> {organisation} -> {days}} ];
	
	my $ix = {};
	
	foreach my $day (@{$data -> {days}}) {
			
		$ix -> {$day -> {day}, $day -> {id_day_period}} = $day;
	
	}
	
	my $default_color = sql_select_scalar ('SELECT color FROM prestation_type_groups WHERE id = -1');

	$data -> {prestation_models} = sql_select_all (<<EOS, $data -> {id}, {fake => 'prestation_models'});
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
	

	foreach my $prestation_model (@{$data -> {prestation_models}}) {
	
#		my $day = $ix -> {$prestation_model -> {day_start}, $prestation_model -> {half_start}} -> {by_mod2} -> [$prestation_model -> {is_odd}];
		my $day = $ix -> {$prestation_model -> {day_start}, $prestation_model -> {half_start}} -> {by_model} -> {$prestation_model -> {id_model}} ||= {};
		
		$day -> {id_prestation_model} = $prestation_model -> {id};
		$day -> {prestation_model_label} = $prestation_model -> {label};
		$day -> {color} = $prestation_model -> {color} || $default_color;
	
	}
	
	sql ($data, models => [
		[id_organisation => $data -> {id_organisation}],
	]);
	
	foreach my $day (@{$data -> {days}}) {
	
		foreach my $model (@{$data -> {models}}) {
		
			my $i = $day -> {by_model} -> {$model -> {id}} ||= {};

			$i -> {href} = $i -> {id_prestation_model} ?
				"/?type=prestation_models&id=$$i{id_prestation_model}&action=delete" :
				"/?type=prestation_models&action=create&id_prestation_type=$_REQUEST{id_prestation_type}&id_user=$$data{id}&day_start=$$day{day}&half_start=$$day{id_day_period}&id_model=$model->{id}";
	
			check_href ($i);

		}
	
	
	}

	return $data;	

}

1;
