columns => {
	id_user => {TYPE_NAME => 'int'},
	id_site => {TYPE_NAME => 'int'},
},

keys => {
	id_user => 'id_user,id_site',
	id_site => 'id_site,id_user',
},

