columns => {				
	id_week_status_type => {TYPE_NAME => 'int'},
	year => {TYPE_NAME => 'int'},
	week => {TYPE_NAME => 'int'},
	id_organisation => {TYPE_NAME => 'int'},
},

keys => {
	id_organisation => 'id_organisation,year,week',
},
