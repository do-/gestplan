columns => {				

	id_prestation  => {TYPE_NAME => 'int'},		
	id_room        => {TYPE_NAME => 'int'},		

	dt_start       => {TYPE_NAME => 'date'},
	half_start     => {TYPE_NAME => 'tinyint'},

	dt_finish      => {TYPE_NAME => 'date'},
	half_finish    => {TYPE_NAME => 'tinyint'},
	
},

keys => {
	id_prestation => 'id_prestation',
	dt_finish => 'dt_finish,half_finish',
	dt_start  => 'dt_start,half_start',
},
