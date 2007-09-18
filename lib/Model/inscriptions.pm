columns => {				

	parent         => {TYPE_NAME => 'int'},

	id_prestation  => {TYPE_NAME => 'int'},
	
	label          => {TYPE_NAME => 'varchar', COLUMN_SIZE  => 255},

	nom            => {TYPE_NAME => 'varchar', COLUMN_SIZE  => 255},
	prenom         => {TYPE_NAME => 'varchar', COLUMN_SIZE  => 255},

	hour           => {TYPE_NAME => 'tinyint'},
	minute         => {TYPE_NAME => 'tinyint'},

	hour_start     => {TYPE_NAME => 'tinyint'},
	minute_start   => {TYPE_NAME => 'tinyint'},

	hour_finish    => {TYPE_NAME => 'tinyint'},
	minute_finish  => {TYPE_NAME => 'tinyint'},

	id_user        => {TYPE_NAME => 'int'},
	id_author      => {TYPE_NAME => 'int'},

	is_unseen      => {TYPE_NAME => 'tinyint', NULLABLE => 0, COLUMN_DEFAULT => 0},

	id_log         => {TYPE_NAME => 'int'},
	
},

keys => {
	'parent'        => 'parent',
	'id_prestation' => 'id_prestation',
},
