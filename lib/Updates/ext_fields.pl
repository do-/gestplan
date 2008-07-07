
sql_do ('TRUNCATE TABLE ext_field_values');

my @ids = sql_select_col ('SELECT id FROM ext_fields WHERE fake = 0');

my $st_s = $db -> prepare ('SELECT * FROM inscriptions');
my $st_i = $db -> prepare ('INSERT INTO ext_field_values (fake, id_inscription, id_ext_field, value) VALUES (0, ?, ?, ?)');

$st_s -> execute ();

while (my $i = $st_s -> fetchrow_hashref) {

	foreach my $id (@ids) {
	
		my $key = "field_$id";
	
		next if $i -> {$key} eq '';
		
		$st_i -> execute ($i -> {id}, $id, $i -> {$key});
	
	}

};