################################################################################

sub do_create_vocs {
	
	$_REQUEST {id} = sql_do_insert ('vocs', {
		id_organisation => $_USER -> {id_organisation}
	});

}

################################################################################

sub do_update_vocs {

	sql_do_update ('vocs', [qw(label)]);
	
	$model_update -> assert (
	
		tables => {	
				
			'voc_' . $_REQUEST {id} => {
	
				columns => {				
					id    => {TYPE_NAME  => 'int', _EXTRA => 'auto_increment', _PK    => 1},
					fake  => {TYPE_NAME  => 'bigint'},
					ord   => {TYPE_NAME => 'int'},
					label => {TYPE_NAME => 'varchar', COLUMN_SIZE  => 255},
				},
				
			},
	
		}
		
	);

}

################################################################################

sub validate_update_vocs {
	
	$_REQUEST {_label} or return "#_label#:Vous avez oublié d'indiquer la désignation de la liste";

	return undef;
	
}

################################################################################

sub get_item_of_vocs {

	my $item = sql_select_hash ('vocs');

	$_REQUEST {__read_only} ||= !($_REQUEST {__edit} || $item -> {fake} > 0);

	$item -> {path} = [
		{type => 'vocs', name => 'Listes choix'},
		{type => 'vocs', name => $item -> {label}, id => $item -> {id}},
	];

	if ($item -> {fake} <= 0) {
		$item -> {items} = sql_select_all ("SELECT * FROM voc_$$item{id} WHERE 1=1 ORDER BY ord", {fake => "voc_$$item{id}"});
	}

	return $item;
	
}

################################################################################

sub select_vocs {

	my $q = '%' . $_REQUEST {q} . '%';

	my $start = $_REQUEST {start} + 0;

	my ($vocs, $cnt)= sql_select_all_cnt (<<EOS, $q, $_USER -> {id_organisation}, {fake => 'vocs'});
		SELECT
			vocs.*
		FROM
			vocs
		WHERE
			(vocs.label LIKE ?)
			AND vocs.id_organisation = ?
		ORDER BY
			vocs.label
		LIMIT
			$start, $$conf{portion}
EOS

	return {
		vocs => $vocs,
		cnt => $cnt,
		portion => $$conf{portion},
	};
}

1;
