################################################################################

sub do_update_organisations_acl {

	$_REQUEST {id} = $_USER -> {id_organisation};
	
	sql_do_update ('organisations', [qw(ids_roles_prestations ids_roles_inscriptions)]);

	delete $_REQUEST {id};

}

################################################################################

sub validate_update_organisations_acl {
	
	my @ids = get_ids ('ids_roles_prestations');
	push @ids, -1;
	unshift @ids, -1;
	$_REQUEST {_ids_roles_prestations} = join ',', @ids;

	my @ids = get_ids ('ids_roles_inscriptions');
	push @ids, -1;
	unshift @ids, -1;
	$_REQUEST {_ids_roles_inscriptions} = join ',', @ids;

	return undef;
	
}

################################################################################

sub select_organisations_acl {
	
	my $item = sql_select_hash ('organisations', $_USER -> {id_organisation});

	$_REQUEST {__read_only} ||= !($_REQUEST {__edit} || $item -> {fake} > 0);
	
	$item -> {ids_roles_prestations}  = [split /\,/, $item -> {ids_roles_prestations}];
	$item -> {ids_roles_inscriptions} = [split /\,/, $item -> {ids_roles_inscriptions}];

	add_vocabularies ($item, 'roles' => {filter => 'id <> 4'});

	$item -> {path} = [
		{type => 'organisations_acl', name => "Droits d'accès"},
#		{type => 'organisations_acl', name => $item -> {label}, id => $item -> {id}},
	];

	return $item;
	
}

1;
