################################################################################

sub select_logon {}

################################################################################

sub validate_execute_logon {

	our $_USER = sql_select_hash ("SELECT * FROM users WHERE fake = 0 AND login = ? AND password = OLD_PASSWORD(?) AND IFNULL(dt_start, NOW()) <= NOW() AND IFNULL(dt_finish, NOW()) >= NOW()", $_REQUEST {login}, $_REQUEST {password});
	
	my $organisation = sql_select_hash ('SELECT * FROM organisations WHERE id = ?', $_USER -> {id_organisation});
	
	$organisation -> {fake} == -1 and return "La compte de votre organisme, $organisation->{label}, est suspendue, pardon.";
		
	undef;	

}

################################################################################

sub do_execute_logon {
	our $_USER = {};
	$_USER -> {id} = sql_select_array ("SELECT id FROM users WHERE fake = 0 AND login = ? AND password = OLD_PASSWORD(?) AND IFNULL(dt_start, NOW()) <= NOW() AND IFNULL(dt_finish, NOW()) >= NOW()", $_REQUEST {login}, $_REQUEST {password});
	$_USER -> {id} or return;
	$_REQUEST {sid} = sql_select_array ("select floor(rand() * 9223372036854775807)");
	sql_do ("DELETE FROM sessions WHERE id_user = ?", $_USER -> {id});
	sql_do ("INSERT INTO sessions (id, id_user) VALUES (?, ?)", $_REQUEST {sid}, $_USER -> {id});
	delete $_REQUEST {type};
	delete $_REQUEST {login};
	delete $_REQUEST {password};
}

1;
