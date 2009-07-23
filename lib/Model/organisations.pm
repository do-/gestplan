aliases => ['partners'],

columns => {				
	label        => {TYPE_NAME => 'varchar', COLUMN_SIZE  => 255},
	ids_partners => {TYPE_NAME => 'varchar', COLUMN_SIZE  => 255},
	href         => {TYPE_NAME => 'varchar', COLUMN_SIZE  => 255},
	ids_roles_prestations  => {TYPE_NAME => 'varchar', COLUMN_SIZE  => 255},
	ids_roles_inscriptions => {TYPE_NAME => 'varchar', COLUMN_SIZE  => 255},
	days         => {TYPE_NAME => 'varchar', COLUMN_SIZE  => 255, NULLABLE => 0, COLUMN_DEF => '1,2,3,4,5'},
	empty_site_label => {TYPE_NAME => 'varchar', COLUMN_SIZE  => 255, COLUMN_DEF => 'Prestations locales'},
},
