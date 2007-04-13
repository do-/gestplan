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

},

keys => {

	dt_finish => 'dt_finish,half_finish',
	id_user   => 'id_user',

},
