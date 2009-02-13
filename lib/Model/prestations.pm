columns => {				

	dt_start    => {TYPE_NAME => 'date'},
	half_start  => {TYPE_NAME => 'tinyint'},

	dt_finish   => {TYPE_NAME => 'date'},
	half_finish => {TYPE_NAME => 'tinyint'},

	id_user     => {TYPE_NAME => 'int'},
	id_users    => {TYPE_NAME => 'varchar', COLUMN_SIZE  => 255},

	id_prestation_type => {TYPE_NAME => 'int'},

	note        => {TYPE_NAME => 'text'},

	id_prestation_model => {TYPE_NAME => 'int'},

	cnt         => {TYPE_NAME => 'int'},

	file_name => {TYPE_NAME    => 'varchar', COLUMN_SIZE  => 255},
	file_type => {TYPE_NAME    => 'varchar', COLUMN_SIZE  => 255},
	file_path => {TYPE_NAME    => 'varchar', COLUMN_SIZE  => 255},
	file_size => {TYPE_NAME    => 'int'},

},

keys => {

	dt_finish => 'dt_finish,half_finish',
	dt_start  => 'dt_start,half_start',
	id_user   => 'id_user',

},
