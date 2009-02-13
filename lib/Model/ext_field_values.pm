columns => {

	id_inscription => {TYPE_NAME => 'int'},
	id_ext_field   => {TYPE_NAME => 'int'},
	value          => {TYPE_NAME => 'text'},

	file_name => {TYPE_NAME    => 'varchar', COLUMN_SIZE  => 255},
	file_type => {TYPE_NAME    => 'varchar', COLUMN_SIZE  => 255},
	file_path => {TYPE_NAME    => 'varchar', COLUMN_SIZE  => 255},
	file_size => {TYPE_NAME    => 'int'},

},

keys => {
	id_inscription => 'id_inscription,id_ext_field',
},

