INSERT INTO file_type (name, description)
VALUES
	('log', 'Free form text output from benchmarking tools'),
	('short_read_fastq', 'Short read sequences in FASTQ format'),
	('reference_fasta', 'Reference sequence in FASTA format'),
	('contig_fasta', 'contigs');

INSERT INTO source_type (name, description)
VALUES
	('metagenome', 'A mixture of multiple genomes'),
	('microbe', 'A single isolated microbe');

INSERT INTO platform_type (name, description)
VALUES
	('miseq', 'Desc');

INSERT INTO protocol_type (name, description)
VALUES
	('regular_fragment', 'Desc');

INSERT INTO run_mode_type (name, description)
VALUES
	('2x150_300', 'Desc');

INSERT INTO image_type (name, description)
VALUES
	('short_read_assembler', 'desc'),
	('short_read_preprocessor', 'desc'),
	('reference_assembly_evaluation', 'desc'),
	('short_read_preprocessing_reference_evaluation', 'desc') ;

INSERT INTO metric_type (name, description)
VALUES
	('ng50', 'desc'),
	('lg50', 'desc');
