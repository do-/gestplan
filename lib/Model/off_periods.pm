columns => {				

	dt_start    => {TYPE_NAME => 'date'},
	half_start  => {TYPE_NAME => 'tinyint'},

	dt_finish   => {TYPE_NAME => 'date'},
	half_finish => {TYPE_NAME => 'tinyint'},

	id_user     => {TYPE_NAME => 'int'},

},

keys => {
	id_user => 'id_user,dt_start,half_start',
}
