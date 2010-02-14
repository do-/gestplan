columns => {
				
	nom    => {TYPE_NAME    => 'varchar', COLUMN_SIZE  => 255},
	prenom => {TYPE_NAME    => 'varchar', COLUMN_SIZE  => 255},
	label  => {TYPE_NAME    => 'varchar', COLUMN_SIZE  => 255},
	mail   => {TYPE_NAME    => 'varchar', COLUMN_SIZE  => 255},

	dt_start    => {TYPE_NAME => 'date'},
	dt_finish   => {TYPE_NAME => 'date'},

	refresh_period  => {TYPE_NAME => 'int', NULLABLE => 0, COLUMN_DEFAULT => 60},

	id_organisation => {TYPE_NAME => 'int'},
	id_role         => {TYPE_NAME => 'int'},
	id_site         => {TYPE_NAME => 'int'},
	id_group        => {TYPE_NAME => 'int'},
	no_popup        => {TYPE_NAME => 'tinyint', NULLABLE => 0, COLUMN_DEFAULT => 0},
	
	options => {TYPE_NAME => 'text'},
	
	id_site_group => 'select(site_groups)', # Secteur	

	html_cache => {TYPE_NAME => 'longtext'},

},

keys => {

	id_organisation => 'id_organisation',

},
