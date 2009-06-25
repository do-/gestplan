################################################################################

sub recalculate_prestation_type_files {

	send_refresh_messages ();

}

################################################################################

sub do_update_prestation_type_files {

	my $uploaded = sql_upload_file ({
		name => 'file',
		dir => 'upload/images',
		table => 'prestation_type_files',
		file_name_column => 'file_name',
		size_column => 'file_size',
		type_column => 'file_type',
		path_column => 'file_path',
	});
	
	$_REQUEST {_label} ||= $uploaded -> {file_name};

	sql_do_update ('prestation_type_files', [qw(label)]);

}

################################################################################

sub validate_update_prestation_type_files {

	my $item = sql_select_hash ('prestation_type_files');

	!$item -> {fake} or $_REQUEST {_file} or return "#_file#:Vous avez oublié de choisir le fichier";
		
	return undef;

}

################################################################################

sub get_item_of_prestation_type_files {

	my $item = sql_select_hash ('prestation_type_files');
	
	$item -> {prestation_type} = sql_select_hash (prestation_types => $item -> {id_prestation_type});

	$_REQUEST {__read_only} ||= !($_REQUEST {__edit} || $item -> {fake} > 0);

	return $item;

}

1;
