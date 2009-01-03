columns => {
	id_user        => {TYPE_NAME => 'int'},
	id_task_status => {TYPE_NAME => 'int'},
	id_task_note   => {TYPE_NAME => 'int'}, #first
	label          => {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
},

keys => {
	id_user => 'id_user,id_task_status',
},

