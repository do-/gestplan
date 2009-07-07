################################################################################

sub recalculate_sites {

	send_refresh_messages ();

}

################################################################################

sub do_update_sites {
	
	sql_do_update ('sites', [qw(
		label
	)]);

}

################################################################################

sub do_create_sites {	

	$_REQUEST {id} = sql_do_insert ('sites', {
		id_organisation => $_USER -> {id_organisation},
	});

}

################################################################################

sub get_item_of_sites {

	my $item = sql_select_hash ('sites');

	$_REQUEST {__read_only} ||= !($_REQUEST {__edit} || $item -> {fake} > 0);
	
	$item -> {path} = [
		{type => 'sites', name => 'Onglets'},
		{type => 'sites', name => $item -> {label}, id => $item -> {id}},
	];

	return $item;
	
}

################################################################################

sub select_sites {

	my $q = '%' . $_REQUEST {q} . '%';

	my $start = $_REQUEST {start} + 0;

	my ($sites, $cnt) = sql_select_all_cnt (<<EOS, $q, $_USER -> {id_organisation}, {fake => 'sites'});
		SELECT
			sites.*
		FROM
			sites
		WHERE
			(sites.label LIKE ?)
			AND sites.id_organisation = ?
		ORDER BY
			sites.label
		LIMIT
			$start, $$conf{portion}
EOS

	return {
		sites => $sites,
		cnt => $cnt,
		portion => $$conf{portion},
	};
	
}

1;
