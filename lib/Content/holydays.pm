
################################################################################

sub validate_update_holydays {

	vld_date ('dt');
	
	!sql_select_scalar ("SELECT id FROM holydays WHERE dt = ? AND fake = 0 AND id_organisation = ? AND id <> ? LIMIT 1", $_REQUEST {_dt}, $_USER -> {id_organisation}, $_REQUEST {id}) or return "#_dt#:Ce jour est déjà férié.";
	
	$_REQUEST {_label} or return "#_label#:Vous avez oublié d'indiquer la désignation";

        $_REQUEST {_is_every_year} += 0;

	return undef;
	
}

################################################################################


sub get_item_of_holydays {

	my $item = sql_select_hash ('holydays');
	
	__d ($item, 'dt');

	$_REQUEST {__read_only} ||= !($_REQUEST {__edit} || $item -> {fake} > 0);

	$item -> {path} = [
		{type => 'holydays', name => 'Jours fériés'},
		{type => 'holydays', name => $item -> {label}, id => $item -> {id}},
	];

#	unless ($_REQUEST {first}) {
#		$_REQUEST {first} = length $item -> {label};
#		$_REQUEST {first} = 4 if $_REQUEST {first} > 4;
#	}
#
#	$item -> {clones} = sql_select_all (<<EOS, $item -> {label}, {fake => 'holydays'});
#		SELECT
#			holydays.*
#		FROM
#			holydays
#		WHERE
#			LEFT(holydays.label, $_REQUEST{first}) = LEFT(?, $_REQUEST{first})
#		ORDER BY
#			holydays.label
#EOS

	return $item;

}

################################################################################

sub do_create_holydays {

	$_REQUEST {id} = sql_do_insert ('holydays', {
		id_organisation  => $_USER -> {id_organisation},
		dt               => sprintf ('%04d-%02d-%02d', Today ()),
	});

}


################################################################################

sub select_holydays {

	my $start = $_REQUEST {start} + 0;
	
	my $filter = '';
	my @params = ();
	
	if ($_REQUEST {q}) {
		$filter .= ' AND holydays.label LIKE ?';
		push @params, '%' . $_REQUEST {q} . '%';	
	}

	my ($holydays, $cnt) = sql_select_all_cnt (<<EOS, $_USER -> {id_organisation}, @params, {fake => 'holydays'});
		SELECT
			holydays.*
		FROM
			holydays
		WHERE
			holydays.id_organisation = ?
			$filter
		ORDER BY
			holydays.dt DESC
		LIMIT
			$start, $$conf{portion}
EOS

	return {
		holydays => $holydays,
		cnt      => $cnt,
		portion  => $$conf{portion},
	};

}

1;
