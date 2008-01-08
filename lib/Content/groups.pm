################################################################################

sub do_update_groups {
	
	sql_do_update ('groups', [qw(
		label
		ord
		is_hidden
	)]);

}

################################################################################

sub do_create_groups {	

	$_REQUEST {id} = sql_do_insert ('groups', {
		id_organisation => $_USER -> {id_organisation},
		ord => 1 + sql_select_scalar ('SELECT MAX(ord) FROM groups WHERE fake = 0 AND id_organisation = ?', $_USER -> {id_organisation}),
	});

}

################################################################################

sub get_item_of_groups {

	my $item = sql_select_hash ('groups');

	$_REQUEST {__read_only} ||= !($_REQUEST {__edit} || $item -> {fake} > 0);
	
	$item -> {path} = [
		{type => 'groups', name => 'Regroupements'},
		{type => 'groups', name => $item -> {label}, id => $item -> {id}},
	];

	return $item;
	
}

################################################################################

sub select_groups {

	my $q = '%' . $_REQUEST {q} . '%';

	my $start = $_REQUEST {start} + 0;

	my ($groups, $cnt) = sql_select_all_cnt (<<EOS, $q, $_USER -> {id_organisation}, {fake => 'groups'});
		SELECT
			groups.*
		FROM
			groups
		WHERE
			(groups.label LIKE ?)
			AND groups.id_organisation = ?
		ORDER BY
			groups.ord
		LIMIT
			$start, $$conf{portion}
EOS

	return {
		groups => $groups,
		cnt => $cnt,
		portion => $$conf{portion},
	};
	
}

1;
