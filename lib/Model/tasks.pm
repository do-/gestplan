columns => {
	id_user                  => {TYPE_NAME => 'int'},
	id_task_status           => {TYPE_NAME => 'int'},
	id_task_note             => {TYPE_NAME => 'int'}, #last
	label                    => {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
	id_task_reproductibility => {TYPE_NAME => 'int'},
	id_task_severity         => {TYPE_NAME => 'int'},
	id_task_priority         => {TYPE_NAME => 'int'},
},

keys => {
	id_user => 'id_user,id_task_status',
},

