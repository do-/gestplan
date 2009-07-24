
################################################################################

sub validate_update_organisations_local {

	my @ids = get_ids ('days');
	@ids > 0 or return "Vous n'avez indiqué aucune jour travaillée";
	$_REQUEST {_days} = join ',', @ids;

	undef;

}

################################################################################

sub do_update_organisations_local {

	sql_do_update ('organisations', [qw(days empty_site_label)]);

}

################################################################################

sub get_item_of_organisations_local { # paramètres de l'organisation actuelle

	my $data = sql (organisations => $_USER -> {id_organisation});
	
	$item -> {days} = [split /\,/, $item -> {days}];

	$_REQUEST {__read_only} ||= !($_REQUEST {__edit} || $item -> {fake} > 0);

	return $data;

}

1;
