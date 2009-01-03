columns => {

	id_user => {TYPE_NAME => 'int'},
	id_task => {TYPE_NAME => 'int'},
	id_log  => {TYPE_NAME => 'int'},
	id_task_status => {TYPE_NAME => 'int', NULLABLE => 0, COLUMN_DEF => 100},

	label   => {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
	body    => {TYPE_NAME => 'longtext'},
	dt      => {TYPE_NAME => 'timestamp'},
#	is_open => {TYPE_NAME => 'tinyint', NULLABLE => 0, COLUMN_DEF => 0},
#	label   => {TYPE_NAME => 'varchar', COLUMN_SIZE => 255}, 
#	price   => {TYPE_NAME => 'decimal', COLUMN_SIZE => 15, DECIMAL_DIGITS => 2}, 

	file_name => {TYPE_NAME    => 'varchar', COLUMN_SIZE  => 255},
	file_type => {TYPE_NAME    => 'varchar', COLUMN_SIZE  => 255},
	file_path => {TYPE_NAME    => 'varchar', COLUMN_SIZE  => 255},
	file_size => {TYPE_NAME    => 'int'},

},

keys => {
	id_task => 'id_task,id',
},

