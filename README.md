# hmt-rename
Script to rename Humax HDR-Fox T2 recordings based on HMT and online metadata

## Usage

	hmt-rename.pl <file>

Where &lt;file&gt; is a file path to the .ts recording, one of the sidecar files, or the base filename without the extension.

Examples:

	hmt-rename.pl /video/Ambassadors/Ambassadors_20131106_2101.hmt
	hmt-rename.pl /video/Ambassadors/Ambassadors_20131106_2101
	hmt-rename.pl /video/Ambassadors/Ambassadors_20131106_2101.ts

## Action

The script will parse the .hmt file, extract the title, episode number and episode name if possible, and query TheTVDB for metadata that the .hmt file does not have (e.g. season number). Files will be renamed like:

	<seriesname>.S<seasonnum>E<episodenum>.<episodename>.ts

For example:

	Ambassadors.S01E01.The Rabbit Never Escapes.ts

## Dependencies

- The hmt tool by af123 (I'm running on my Linux server, thus http://hpkg.tv/misc/hmt-linux)
- The WebService::TVDB Perl module

## Limitations

* Assumes that files are TV series episodes.
* Makes assumptions about the Freeview EPG data present. Namely that there is a Title field with the name of the Programme (e.g. Ambassadors), and that the synopsis field looks like:  
<pre>1/3: Episode title. The rest of the episide description</pre>
