[]
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"><html lang="en"><head>
<meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>%folder%</title>
<link rel="icon" href="data:image/gif;base64,R0lGODlhEAAQAPIBABAhShAAAIx/KWeFav/vKSRWjDl7ztPMwyH5BAEAAAAALAAAAAAQABAAAANRCLrcPiee4dSAMt528zGXIDCXERloOFoD6l6DKCpF/cayQAG1DeYwWq8GKxYAgaRyyUwSnAGC9CmYQqNY5XM5fU4FgSoBnPU2y9CtU0o+K5oJADs=">
<style>body{background:#E6EBFA;overflow-x:hidden;padding:0px 3px 0px 0px;font-weight:400;color:#333;font-family:"Arial Unicode MS","Lucida Sans Unicode","DejaVu Sans",sans-serif;margin:0}
a{text-decoration:none;font-size:16pt;color:#00D;font-weight:400} a:visited{color:#808} a:hover{color:#000}</style>
 <script type="text/javascript">function browseAbleFolderTree(e){var a=e.split("/"),t="/",r="";for(pta=1;pta<a.length;pta++)r=r+'/<a href="'+(t=t+a[pta]+"/")+'" class="swapDir">'+a[pta]+"</a>";document.getElementById("swapDir").innerHTML=r}</script>
 <script type="text/javascript">function searchQuery(){if(frm=document.searchForm,frm.query.value.length<3)alert("Search requires 3 or more characters");else{for(recursive=frm.recursive.checked?"&recursive":"",x=0;x<frm.choice.length;x++)1==frm.choice[x].checked&&(filter="file"==frm.choice[x].value?(searchMode="?files-filter=","&folders-filter=%5C"):"folder"==frm.choice[x].value?(searchMode="?folders-filter=","&files-filter=%5C"):(searchMode="?filter=",""));for(c=0;c<frm.root.length;c++)1==frm.root[c].checked&&(searchFrom="current"==frm.root[c].value?"http://%host%%folder%":"http://%host%");document.location.href=searchFrom+searchMode+"*"+frm.query.value+"*"+recursive+filter}}</script>
	<link rel="stylesheet" href="/~icons.css" type="text/css">
	<link rel="stylesheet" href="/~nomacros_style.css" type="text/css">
	<script type="text/javascript" src="/~nomacros_lib.js"></script>
</head>
<body>
	<div id="wrapper">
<script>
$domReady(()=>{
	if ($sel('#menu-panel').style.position.indexOf('sticky') < 0) // sticky is not supported
		setInterval(()=>
			$sel('#wrapper').style.marginTop = $sel('#menu-panel').clientHeight+5, 300); // leave space for the fixed panel
});
</script>

<div id='menu-panel'>
	<div id="title-bar">
<i class="fa fa-globe"></i> HTTP File Server
<i class="fa fa-lightbulb" id="switch-theme"></i>
<script>
var themes = ['light','dark']
var themePostfix = '-theme'
var darkOs = window.matchMedia('(prefers-color-scheme:dark)').matches
var curTheme = localStorage['theme']
if (!themes.includes(curTheme))
	curTheme = themes[+darkOs]
var body = document.body
body.classList.add(curTheme+themePostfix)
$domReady(()=>{

    var titleBar = $sel('#title-bar')
	var h = titleBar.clientHeight
	var k = 'shrink'
    window.onscroll = function(){
        if (window.scrollY > h)
        	titleBar.classList.add(k)
		else if (!window.scrollY)
            titleBar.classList.remove(k)
    }

    $click('#switch-theme', ()=>{
        $xclass(body, curTheme+themePostfix);
		curTheme = themes[themes.indexOf(curTheme) ^1]
        $xclass(body, curTheme+themePostfix);
        localStorage.setItem('theme', curTheme);
    });
});
</script>
<style>
	#title-bar { color:white; height:1.5em; transition:height .2s ease; overflow:hidden; position: relative; top: 0.2em;font-size:120%; }
	#title-bar.shrink { height:0; }
	#foldercomment { clear:left; }
	#switch-theme { color: #aaa; position: absolute; right: .5em; }
</style>
	</div>
	<div id="menu-bar">
		<button id="multiselection" title="Enable multi-selection" onclick='toggleSelection()'>
			<i class='fa fa-check'></i>
			<span>Selection</span>
		</button>
		<button id="toggleTs" title="Display timestamps" onclick="toggleTs()">
			<i class='fa fa-clock'></i>
			<span>Toggle timestamp</span>
		</button>

			<button id="upload" onclick="upload()" title="Upload">
				<i class='fa fa-upload'></i>
				<span>Upload</span>
			</button>

		<button id="sort" title="Change list order" onclick="changeSort()">
			<i class='fa fa-sort'></i>
			<span>Sort</span>
		</button>
	</div>

    <div id="additional-panels">
<div id="upload-panel" class="additional-panel closeable" style="display:none">
	<div id="upload-counters">
		Uploaded: <span id="upload-ok">0</span>
		<span style="display:none"> - Failed: <span id="upload-ko">0</span></span>
		- Queued: <span id="upload-q">0</span>
	</div>
	<div id="upload-results"></div>
	<div id="upload-progress">
		Uploading... <span id="progress-text"></span>
		<progress max="1"></progress>
	</div>
	<button onclick="reload()"><i class="fa fa-refresh"></i> Reload page</button>
</div>
		<div id="selection-panel" class="additional-panel" style="display:none">
			<label><span id="selected-counter">0</span> selected</label>
			<span class="buttons">
				<button id="select-mask"><i class="fa fa-asterisk"></i><span>Mask</span></button>
				<button id="select-invert"><i class="fa fa-retweet"></i><span>Invert</span></button>
				<button id="delete-selection"><i class="fa fa-trash"></i><span>Delete</span></button>
				<button id="move-selection"><i class="fa fa-truck"></i><span>Move</span></button>
				<button id='archive' title="Download selected files as a single archive">
					<i class="fa fa-file-archive"></i>
					<span>Archive</span>
				</button>
			</span>
		</div>
    </div>
</div>

	</div>
<div style="font-size:15pt;color:#337"><a href="/">&#127968;</a><span id=swapDir>%folder%</span><script type="text/javascript">browseAbleFolderTree("%folder%")</script></div>
<div>%files%</div></div>
</body>

<script>function music(){ //C DJ BSD2License
var e=1,n=new Audio,o=[[]],c=0,r=[];document.querySelectorAll("a[href]").forEach(function(t,e){var n;[".mp3",".ogg",".m4a",".wma",".aac","flac",".Mp3",".MP3",".OGG",".M4A",".WMA",".AAC","FLAC"].indexOf(t.getAttribute("href").slice(-4))+1&&(o[0].push(t.getAttribute("href")),t.addEventListener("click",function(e){e.preventDefault(),i(t.getAttribute("href"))}),(n=document.querySelector('input[value="'+t.getAttribute("href")+'"]'))&&(n.checked=!0))}),"?shuffle"==location.search&&(e=!e),e&&(o[0]=o[0].sort(function(e,t){return.5-Math.random()}));var t,u=document.querySelector("#actions")||document.querySelector("#menu-bar")||document.querySelector("body"),a=document.createElement("button");function i(e){e.match(/m3u8?$/)?fetch(e).then(function(e){e.text().then(function(e){i(e.match(/^(?!#)(?!\s).*$/gm).map(encodeURI)[0])})}):(n.src=e,n.play(),document.title=decodeURI(e))}a.textContent="\u25BA",a.setAttribute("class","play"),a.onclick=function(){n.paused?(n.src||(n.src=(e?o[0]:t)[0]),n.play()):n.pause()},a.oncontextmenu=function(e){e.preventDefault(),n.onended()},o[0].length&&!document.querySelector("button.play")&&u.appendChild(a),n.onended=function(){var e=n.getAttribute("src");do{e=o[c][o[c].indexOf(e)+1];var t=document.querySelector('input[value="'+e+'"]')}while(t&&!t.checked);e?i(e):c?(c--,n.src=r[c],n.onended()):i(o[0][0])},n.onpause=function(){document.querySelector("button.play").textContent="\u25BA"},n.onplay=function(){document.querySelector("button.play").textContent="\u2759 \u2759"},o[0].length&&(window.onbeforeunload=function(e){localStorage.last=n.getAttribute("src")+"#t="+n.currentTime},t=localStorage.last.split("#t="),n.preload="none",n.src=(e?o[0]:t)[0],(t=1e3*location.search.slice(1))&&setTimeout(function(){document.querySelector("button.play").click()},t)),n.onerror=function(){n.onended()},"mediaSession"in navigator&&navigator.mediaSession.setActionHandler("nexttrack",function(){n.onended()})}document.querySelector("main")||music();</script>
</html>

[files]
<table border="0" style="font-size:8pt;color:#337" width="100%">
<tr><td><nobr id='menu-bar'>Sort&ensp;<a href="%encoded-folder%?sort=n" style="font-size:8pt"><u>Name</u></a>,&ensp;<a href="%encoded-folder%?sort=e" style="font-size:8pt"><u>Type</u></a>,&ensp;<a href="%encoded-folder%?sort=!t" style="font-size:8pt"><u>Date</u></a>&nbsp;&nbsp;&nbsp;</nobr></td></tr>
<tr><td><form class=hide name=searchForm method=GET action="javascript:searchQuery()"><input style="padding:0;border:1;" placeholder="search" type=input name=query size=23 maxlength=32/><input type=hidden name=choice value="file"/><input type=hidden name=choice value="folder"/><input type=hidden name=choice value="both" checked=1/><input type=hidden name=recursive checked=1/><input type=hidden name=root value="root"/><input type=hidden name=root value="current" checked=1/></form></td></tr>
</table>
<div class="table_title">Files for download:&emsp;</div>
<font size="2"><div id="files">%list%</div></font>

[special:alias|cache]

[file.jpg = file.JPG = file.jpeg = file.png = file.gif = file.tif = file.bmp = file.webp]
<div class="list"><nobr><a class="l" href="%item-url%"><font color="black" size="4">&#128247;</font>&nbsp;%item-name%</a>
<span class="t">%item-modified%, %item-size%<font class='d' dlz='%item-url%'></font></span></nobr></div>

[file.mp4 = file.m4v = file.mkv = file.flv = file.avi = file.wmv = file.webm = file.mov]
<div class="list"><nobr><a class="l" href="%item-url%"><font color="teal" size="4">&#127909;</font>&nbsp;%item-name%</a>
<span class="t">%item-modified%, %item-size%<font class='d' dlz='%item-url%'></font></span></nobr></div>

[file.mp3 = file.m4a = file.wma = file.flac = file.ogg = file.aac]
<div class="list"><nobr><a class="l" href="%item-url%"><font color="green" size="4">&#128266;</font>&nbsp;%item-name%</a>
<span class="t">%item-modified%, %item-size%<font class='d' dlz='%item-url%'></font></span></nobr></div>

[file.doc = file.odt = file.docx = file.xls = file.ods = file.xlsx = file.pdf = file.mobi = file.epub = file.lit = file.txt]
<div class="item"><nobr><a class="l" href="%item-url%"><font color="#BBBBBB" size="4">&#128196;</font>&nbsp;%item-name%</a>
<span class="t">%item-modified%, %item-size%<font class='d' dlz='%item-url%'></font></span></nobr></div>

[file]
<div class="item"><nobr><a class="l" href="%item-url%"><font size="4">&#128311;</font>&nbsp;%item-name%</a>
<span class="t">%item-modified%, %item-size%<font class='d' dlz='%item-url%'></font></span></nobr></div>

[link]
<div class="item"><nobr><a href="%item-url%"><font color="purple" size="4">&#128279;</font>&nbsp;%item-name%</a>
<span class="t"><font color="#AAAAAA"><i>link&nbsp;</i></font></span></nobr></div>

[folder]
<div class="item">
<nobr><a class="l" href="%item-url%"><font color="orange" size="4">&#128193;</font>&nbsp;<b>%item-name%</b></a>
<span class="t">%item-modified% <font class='d' dlz='%item-url%'></font></span></nobr></div>

[nofiles]
%url%<a href="%encoded-folder%"><a href="../" style="text-decoration:none;color:purple"><br>&#8678; Back</a>

[api level]
999

[error-page]
%content%

[overload]

[max contemp downloads]

[server is busy|public]
<!DOCTYPE html><html><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<META HTTP-EQUIV="Refresh" CONTENT="3;URL=%url%"><TITLE>Busy</TITLE><link rel="icon" href="data:,"></head>
<body bgcolor="#E6EBFA"><center><h2><br>Server is busy.</h2>Returning to previous page...</center></body></html>

[not found]
<!DOCTYPE html><html><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<META HTTP-EQUIV="Refresh" CONTENT="1;URL=../"><TITLE>404</TITLE><link rel="icon" href="data:,"></head>
<body bgcolor="#E6EBFA"><center><h2><br>Folder Not Found.</h2>Returning to previous page...</center></body></html>

[404|public]
<!DOCTYPE html><html><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<META HTTP-EQUIV="Refresh" CONTENT="2;URL=%url%"><TITLE>404</TITLE><link rel="icon" href="data:,"></head>
<body bgcolor="#E6EBFA"><center><h2><br>File Not Found.</h2>Returning to previous page...</center></body></html>

[unauth]

[deny]

[ban]

[upload|public]
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"><html><head><title>Upload to: %folder%</title>
<meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1"><link rel="icon" href="data:,">
<script type="text/javascript">var counter=0;function addUpload(){++counter<"6"&&(document.getElementById("addupload").innerHTML+='<br><input name="fileupload'+counter+'" size="50" type="file">'),"5"==counter&&(document.getElementById("addUploadLink").innerHTML='<a style="cursor:text;color:yellow;">- PLEASE PUT MULTIPLE FILES INTO A ZIP FILE -</a>')}</script>
</head>
<body bgcolor="#000033" text="white" style="font-family:'Arial Unicode MS','Lucida Sans Unicode','DejaVu Sans',sans-serif;margin:0;padding:0">
<a href="./" style="text-decoration:none"><font color=gray><b>Upload to:</b> %folder%</font><br><font color=yellow>&#8678; Back</font></a><center><h3><br><br>
Upload is not available to due to high server load.<br><br>Automatically retrying in <span id=timer></span> seconds...</h3></center>
<script>setTimeout(function(){window.location.href="./~upload"},5e3),window.onload=function(){var n=5;setInterval(function(){document.getElementById("timer").innerHTML=n,0==--n&&(hour--,n=60)},1e3)};</script>
:}|{:
<div><a href="./" style="text-decoration:none"><font color=gray><b>Upload to:</b> %folder%</font><br><font color=yellow>&#8678; Back</font></a></div><div><center><font size="1"><br></font><b>You can upload files into the<br>%diskfree% available space.</b><br><br>
<form action="%encoded-folder%" target=_parent method=post enctype="multipart/form-data" onSubmit="frm.upbtn.disabled=true; return true;"><div id=addupload>First: <input name="fileupload1" size=50 type=file></div><a id=addUploadLink style="cursor:pointer;" onclick="addUpload();"><br>&emsp;+&emsp;</a><br><br>And then: <input name=upbtn type=submit value="Send File(s)"></form><font size="2">Results page appears after uploads complete</font></center></div>
</body></html>

[upload-results]
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"><html><head><meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1"><META HTTP-EQUIV="Refresh" CONTENT="2;URL=./">
<title>Upload results for: %folder%</title><link rel="icon" href="data:,"></head>
<body bgcolor="#000033" text="white" alink="green" link="blue" vlink="purple" style="font-family:'Arial Unicode MS','Lucida Sans Unicode','DejaVu Sans',sans-serif;margin:0;padding:0">
<div>Upload results for: %folder%</div><div>%uploaded-files%<br><br><a href="%encoded-folder%" target=_parent><font color="yellow">&#8678; Back</font></a></div></body></html>

[upload-success]
<b>SUCCESS!</b> Uploaded: %item-name% - %item-size%

[upload-failed]
Error: %item-name%: - %reason%

[special:import]

[+special:strings]
option.comment=0

[newfile]

[ajax.changepwd|public|no log]

[login|public]

