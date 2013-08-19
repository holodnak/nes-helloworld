;;nes registers
.define PPUCTRL		$2000
.define PPUMASK		$2001
.define PPUSTATUS		$2002
.define OAMADDR		$2003
.define OAMDATA		$2004
.define PPUSCROLL		$2005
.define PPUADDR		$2006
.define PPUDATA		$2007

;;work ram address
.define WORK_RAM		$0300

;;timer data
.define TIME_FRAMES		WORK_RAM+32
.define TIME_SECONDS		WORK_RAM+33
.define TIME_MINUTES		WORK_RAM+34

;;scroll x
.define SCROLL_X			WORK_RAM+16