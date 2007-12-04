################################################################################

sub draw_alerts {
	
	my ($data) = @_;

	my $text = '';
	
	my $ids = '-1,';
	
	foreach my $alert (@{$data -> {alerts}}) {
	
		$text .= "$$alert{nom} $$alert{prenom} est arriv�(e) � $$alert{hour}h$$alert{minute}.\\n";
		
		$ids  .= $alert -> {id};
		$ids  .= ',';
	
	}
	
	$ids  .= '-1';

	$text or return '';
	
	my $salt = rand * time;

	return <<EOH;
		<script>
			window.focus ();
			alert ("$text");
//			nope ("/?sid=$_REQUEST{sid}&type=alerts&action=purge&_ids=$ids", '_self');
//			window.parent.document.location = window.parent.document.location + '&_salt=' + $salt;
		</script>
EOH

}

1;
