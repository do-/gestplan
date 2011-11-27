columns => {		

	id_model    => '(models)',		

	day_start   => {TYPE_NAME => 'int'},
	half_start  => {TYPE_NAME => 'tinyint'},

	day_finish  => {TYPE_NAME => 'int'},
	half_finish => {TYPE_NAME => 'tinyint'},

	id_user     => {TYPE_NAME => 'int'},
	id_users    => {TYPE_NAME => 'varchar', COLUMN_SIZE  => 255},

	id_prestation_type => {TYPE_NAME => 'int'},

	note        => {TYPE_NAME => 'text'},
	is_odd      => {TYPE_NAME => 'tinyint', NULLABLE => 0, COLUMN_DEFAULT => 0},

},

keys => {
	id_user => 'id_user',
},
