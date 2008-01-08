################################################################################

sub do_update_ext_fields {

	sql_do_update ('ext_fields', [qw(
		label
		id_field_type
		id_voc
		length
		ord
		is_mandatory
	)]);
	
	my $item = sql_select_hash ('ext_fields');
	
	my $ext_field_type = sql_select_hash ('ext_field_types', $item -> {id_field_type});
	
	my $definition = {
		TYPE_NAME => $ext_field_type -> {sql_type},
	};
	
	if ($item -> {length} > 0) {
		$definition -> {COLUMN_SIZE} = $item -> {length};
	}

	$model_update -> assert (
	
		tables => {	
				
			inscriptions => {
					
				columns => {				
					'field_' . $item -> {id} => $definition,
				},
				
			},
	
		}
		
	);	

}

################################################################################

sub do_create_ext_fields {

	$_REQUEST {id} = sql_do_insert ('ext_fields', {
		label           => '',
		ord             => 10 + sql_select_scalar ('SELECT MAX(ord) FROM ext_fields WHERE fake = 0'),
		id_organisation => $_USER -> {id_organisation},
	});

}

################################################################################

sub validate_update_ext_fields {
	
	$_REQUEST {_label} or return "#_label#:Vous avez oublié d'indiquer la désignation";
	
	$_REQUEST {_id_field_type} or return "#_id_field_type#:Vous avez oublié d'indiquer la nature";
	
	my $ext_field_type = sql_select_hash ('ext_field_types', $_REQUEST {_id_field_type});
	
	if ($ext_field_type -> {max_len} > 0) {	
		$_REQUEST {'_length_' . $ext_field_type -> {id}} > 0 or return "#_length_$$ext_field_type{id}#:Vous avez oublié d'indiquer la dimension";
		$_REQUEST {'_length_' . $ext_field_type -> {id}} < $ext_field_type -> {max_len} or return "#_length_$$ext_field_type{id}#:La dimension pour cette nature de données est limitée par " . $ext_field_type -> {max_len};
		$_REQUEST {_length} = $_REQUEST {'_length_' . $ext_field_type -> {id}};
	}
	
	$_REQUEST {_is_mandatory} += 0;

	return undef;
	
}

################################################################################

sub get_item_of_ext_fields {

	my $item = sql_select_hash ('ext_fields');

	$_REQUEST {__read_only} ||= !($_REQUEST {__edit} || $item -> {fake} > 0);

#	add_vocabularies ($item, 'ext_field_types');
	
	$item -> {ext_field_types} = sql_select_all ('SELECT * FROM ext_field_types WHERE fake = 0 ORDER BY label');
	
	foreach my $type (@{$item -> {ext_field_types}}) {
		
		if ($type -> {max_len}) {
			
			$type -> {type}  = 'string';
			$type -> {name}  = 'length_' . $type -> {id};
			$type -> {size}  = 3;
			$type -> {value} = $item -> {length};
			
		}
		elsif ($type -> {id} == 1) {

			$type -> {type}   = 'select';
			$type -> {name}   = 'id_voc';
#			$type -> {empty}  = 'Utilisateurs';
			$type -> {other}  = '/?type=vocs';
			$type -> {values} = [{id => 0, label => 'Utilisateurs'}, @{sql_select_vocabulary ('vocs', {filter => 'id_organisation = ' . $_USER -> {id_organisation}})}];			

		}
		
	}

	$item -> {path} = [
		{type => 'ext_fields', name => 'Types de données'},
		{type => 'ext_fields', name => $item -> {label}, id => $item -> {id}},
	];

	return $item;
	
}

################################################################################

sub select_ext_fields {

	my $q = '%' . $_REQUEST {q} . '%';

	my $start = $_REQUEST {start} + 0;

	my ($ext_fields, $cnt)= sql_select_all_cnt (<<EOS, $q, $_USER -> {id_organisation}, {fake => 'ext_fields'});
		SELECT
			ext_fields.*
			, ext_field_types.label AS ext_field_types_label
			, vocs.label AS voc_label
		FROM
			ext_fields
			INNER JOIN ext_field_types ON ext_fields.id_field_type = ext_field_types.id
			LEFT  JOIN vocs ON ext_fields.id_voc = vocs.id
		WHERE
			(ext_fields.label LIKE ?)
			AND ext_fields.id_organisation = ?
		ORDER BY
			ext_fields.ord
		LIMIT
			$start, $$conf{portion}
EOS

	return {
		ext_fields => $ext_fields,
		cnt => $cnt,
		portion => $$conf{portion},
	};
	
}

1;
