################################################################################

sub recalculate_user_options {

	send_refresh_messages ();

}

################################################################################

sub do_update_user_options {
	
	sql_do_update ('users', [qw(login refresh_period no_popup)]);

	$_REQUEST {_password} and sql_do ("UPDATE users SET password=OLD_PASSWORD(?) WHERE id=?", $_REQUEST {_password}, $_REQUEST {id});

	delete $_REQUEST {id};

}

################################################################################

sub validate_update_user_options {

	$_REQUEST {id} = $_USER -> {id};	
	
	$_REQUEST {_login} ||= $_USER -> {login};
	
	$_REQUEST {_login} =~ /^\w+$/ or return "#_login#:Désolé, vous avez choisi un login invalide";

	vld_unique ('users', {field => 'login'}) or return "#_login#:Le login '$_REQUEST{_login}' est déjà occupé, veuillez choisir un autre";

	return undef;
	
}

################################################################################

sub select_user_options {

	my $item = sql_select_hash ("users", $_USER -> {id});
	
	$item -> {refresh_period} ||= 300;
		
	$_REQUEST {__read_only} ||= !($_REQUEST {__edit} || $item -> {fake} > 0);	

	$item -> {path} = [
		{type => 'user_options', name => 'Mes options'},
	];

	return $item;	

}

1;
