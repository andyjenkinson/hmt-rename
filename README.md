# hmt-rename
Script to rename Humax HDR-Fox T2 recordings based on HMT and online metadata

Usage: hmt-rename.pl <file>

Where <file> is a file path to the .ts recording, one of the sidecar files, or the base filename without the extension.
Example: hmt-rename.pl /video/Ambassadors/Ambassadors_20131106_2101.hmt
Example: hmt-rename.pl /video/Ambassadors/Ambassadors_20131106_2101
Example: hmt-rename.pl /video/Ambassadors/Ambassadors_20131106_2101.ts

The script will parse the .hmt file, extract the title, episode number and episode name if possible, and query TheTVDB for metadata that the .hmt file does not have (e.g. season number). Files will be renamed like:
	<seriesname>.S<seasonnum>E<episodenum>.<episodename>.ts
For example:
	Ambassadors.S01E01.The Rabbit Never Escapes.ts
