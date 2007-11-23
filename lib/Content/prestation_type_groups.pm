################################################################################

sub do_update_prestation_type_groups {

	my $item = sql_select_hash ('prestation_type_groups');
	
	my @fields = ('label');
	
	push @fields, 'color' if $item -> {fake};

	sql_do_update ('prestation_type_groups', \@fields);

	sql_do ('DELETE FROM prestation_type_group_colors WHERE id_prestation_type_group = ? AND id_organisation = ?', $_REQUEST {id}, 0 + $_USER -> {id_organisation});
	
	sql_do_insert ('prestation_type_group_colors', {
		fake                     => 0,
		id_prestation_type_group => $_REQUEST {id},
		id_organisation          => $_USER -> {id_organisation},
		color                    => $_REQUEST {_color},
	});

}

################################################################################

sub get_item_of_prestation_type_groups {

	my $item = sql_select_hash ('prestation_type_groups');
	
	my $prestation_type_group_color = sql_select_hash ('SELECT * FROM prestation_type_group_colors WHERE id_prestation_type_group = ? AND id_organisation = ?', $item -> {id}, 0 + $_USER -> {id_organisation});
	
	$item -> {color} = $prestation_type_group_color -> {color} if $prestation_type_group_color -> {id};

	$_REQUEST {__read_only} ||= !($_REQUEST {__edit} || $item -> {fake} > 0);

	$item -> {path} = [
		{type => 'prestation_type_groups', name => 'Couleurs'},
		{type => 'prestation_type_groups', name => $item -> {label}, id => $item -> {id}},
	];

	return $item;
	
}

################################################################################

sub select_prestation_type_groups {

	my $q = '%' . $_REQUEST {q} . '%';

	my $start = $_REQUEST {start} + 0;

	my ($prestation_type_groups, $cnt)= sql_select_all_cnt (<<EOS, 0 + $_USER -> {id_organisation}, $q, {fake => 'prestation_type_groups'});
		SELECT
			prestation_type_groups.*
			, IFNULL(prestation_type_group_colors.color, prestation_type_groups.color) AS color
		FROM
			prestation_type_groups
			LEFT JOIN prestation_type_group_colors ON (
				prestation_type_group_colors.id_prestation_type_group = prestation_type_groups.id
				AND prestation_type_group_colors.id_organisation = ?
			)
		WHERE
			(prestation_type_groups.label LIKE ?)
		ORDER BY
			prestation_type_groups.label
		LIMIT
			$start, $$conf{portion}
EOS

	return {
		prestation_type_groups => $prestation_type_groups,
		cnt => $cnt,
		portion => $$conf{portion},
	};
	
}

1;
