################################################################################

sub recalculate_voc_items {

	send_refresh_messages ();

}

################################################################################

sub do_undelete_voc_items {
	
	sql_do ("UPDATE voc_$_REQUEST{id_voc} SET fake = 0 WHERE id = ?", $_REQUEST {id});	
	esc ();

}

################################################################################

sub do_delete_voc_items {
	
	sql_do ("UPDATE voc_$_REQUEST{id_voc} SET fake = -1 WHERE id = ?", $_REQUEST {id});	
	esc ();

}

################################################################################

sub validate_update_voc_items {
	
	$_REQUEST {_label} or return "#_label#:Vous avez oublié d'indiquer la désignation";

	return undef;
	
}

################################################################################

sub do_update_voc_items {
	
	my $table = 'voc_' . $_REQUEST {id_voc};

	sql_do_update ($table, [qw(label ord)]);

}

################################################################################

sub do_creer_voc_items {

	my $table = 'voc_' . $_REQUEST {id_voc};
	
	delete_fakes ($table);
	
	my $ord = 10 + sql_select_scalar ("SELECT MAX(ord) FROM $table WHERE fake = 0");

	$_REQUEST {id} = sql_do_insert ($table, {
		label => '',
		ord   => $ord,
	});

}

################################################################################

sub get_item_of_voc_items {
	
	my $voc   = sql_select_hash ('vocs', $_REQUEST {id_voc});

	my $table = 'voc_' . $_REQUEST {id_voc};

	my $item  = sql_select_hash ($table);

	$_REQUEST {__read_only} ||= !($_REQUEST {__edit} || $item -> {fake} > 0);

	$item -> {path} = [
		{type => 'vocs', name => 'Listes'},
		{type => 'vocs', name => $voc -> {label}, id => $voc -> {ids}},
		{type => 'voc_items', name => $item -> {label}, id => $item -> {id}},
	];

	return $item;
}

1;
