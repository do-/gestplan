columns => {
	id_inscription => {TYPE_NAME => 'int'},
	id_ext_field   => {TYPE_NAME => 'int'},
	value          => {TYPE_NAME => 'text'},
},

keys => {
	id_inscription => 'id_inscription,id_ext_field',
},

