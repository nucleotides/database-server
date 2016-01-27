INSERT INTO file_type (name, description)
VALUES
	('short_read_fastq', 'Short read sequences in FASTQ format'),
	('reference_fasta', 'Reference sequence in FASTA format');

INSERT INTO source_type (name, description)
VALUES
	('metagenome', 'A mixture of multiple genomes'),
	('microbe', 'A single isolated microbe');
