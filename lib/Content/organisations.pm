################################################################################

sub do_update_organisations {
	
		sql_do_update ('organisations', [qw(label ids_partners href)]);

}

################################################################################

sub validate_update_organisations {
	
	$_REQUEST {_label} or return "#_label#:Vous avez oublié d'entrer la désignation";
	
	my @ids = get_ids ('ids_partners');
	push @ids, -1;
	unshift @ids, -1;
	$_REQUEST {_ids_partners} = join ',', @ids;

	return undef;
	
}

################################################################################

sub get_item_of_organisations {

	my $item = sql_select_hash ('organisations');
	
	$item -> {ids_partners} = [split /\,/, $item -> {ids_partners}];
	
	add_vocabularies ($item,
		organisations => {filter => "id <> $$item{id}"},
	);

	$_REQUEST {__read_only} ||= !($_REQUEST {__edit} || $item -> {fake} > 0);

	$item -> {path} = [
		{type => 'organisations', name => 'Organisations'},
		{type => 'organisations', name => $item -> {label}, id => $item -> {id}},
	];

#	unless ($_REQUEST {first}) {
#		$_REQUEST {first} = length $item -> {label};
#		$_REQUEST {first} = 4 if $_REQUEST {first} > 4;
#	}
#
#	$item -> {clones} = sql_select_all (<<EOS, $item -> {label}, {fake => 'organisations'});
#		SELECT
#			organisations.*
#		FROM
#			organisations
#		WHERE +
#			LEFT(organisations.label, $_REQUEST{first}) = LEFT(?, $_REQUEST{first})
#		ORDER BY
#			organisations.label
#EOS

	return $item;
	
}

################################################################################

sub select_organisations {

	my $q = '%' . $_REQUEST {q} . '%';

	my $start = $_REQUEST {start} + 0;

	my ($organisations, $cnt)= sql_select_all_cnt (<<EOS, $q, {fake => 'organisations'});
		SELECT
			organisations.*
		FROM
			organisations
		WHERE
			(organisations.label LIKE ?)
		ORDER BY
			organisations.label
		LIMIT
			$start, $$conf{portion}
EOS

	return {
		organisations => $organisations,
		cnt => $cnt,
		portion => $$conf{portion},
	};
}

1;
