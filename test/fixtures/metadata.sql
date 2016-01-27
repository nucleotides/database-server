INSERT INTO file_type (name, description)
VALUES
	('short_read_fastq', 'Short read sequences in FASTQ format'),
	('reference_fasta', 'Reference sequence in FASTA format');

INSERT INTO source_type (name, description)
VALUES
	('metagenome', 'A mixture of multiple genomes'),
	('microbe', 'A single isolated microbe');

INSERT INTO platform_type (name, description)
VALUES
	('illumina', 'Illumina sequencing platform');

INSERT INTO product_type (name, description)
VALUES
	('random', 'DNA extraction followed by random DNA sequencing');

INSERT INTO protocol_type (name, description)
VALUES
	('nextera', 'Illumina nextera protocol');

INSERT INTO run_mode_type (name, description)
VALUES
	('2x150_270', 'An insert size of 270bp sequenced with 2x150bp reads');
