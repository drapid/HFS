Welcome! This is the default template for HFS 2.3

Here below you'll find some options affecting the template.
Consider 1 is used for "yes", and 0 is used for "no".

DO NOT EDIT this template just to change options. It's a very bad way to do it, and you'll pay for it!
Correct way: in Virtual file system, right click on home/root, properties, diff template,
put this text [+special:strings]
and following all the options you want to change, using the same syntax you see here.

[+special:strings|private]
option.paged=1
COMMENT this option causes your file list to be paged by default

option.newfolder=1
option.move=1
option.comment=1
option.rename=1
COMMENT with these you can disable some features of the template. Please note this is not about user permissions, this is global!

[]
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN">
<html>
<head>
	<meta http-equiv="content-type" content="text/html; charset=UTF-8">
	<title>HFS %folder%</title>
	<link rel="stylesheet" href="/?mode=section&id=style.css" type="text/css">
 	<script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.4.2/jquery.js"></script>
    <script> if (typeof jQuery == "undefined") document.write('<script type="text/javascript" src="/?mode=jquery"></'+'script>'); </script>
	<link rel="shortcut icon" href="/favicon.ico">
	<style class='trash-me'>
	.onlyscript, button[onclick] { display:none; }
	</style>
    <script>
    // this object will store some %symbols% in the javascript space, so that libs can read them
    HFS = { folder:'{.js encode|%folder%.}', number:%number%, paged:{.!option.paged.} }; 
    </script>
	<script type="text/javascript" src="/?mode=section&id=lib.js"></script>
	<script type="text/javascript" src="/?mode=section&id=md5.js"></script>
</head>
<body>
<!--{.comment|--><h1 style='margin-bottom:100em'>WARNING: this template is only to be used with HFS 2.3 (and macros enabled)</h1> <!--.} -->
<div id='panel'>
	<fieldset id='msgs'>
		<legend><img src="/~img10"> {.!Messages.}</legend>
		<ul style='padding-left:2em'>
		</ul>
	</fieldset>
		
	<fieldset id='login'>
		<legend><img src="/~img27"> {.!Login.}</legend>
		<center>
		{.if| %user% |{:
            %user%            
            <button onclick='logout()'>logout</button>
            {.if|{.can change pwd.} | 
                <button onclick='changePwd.call(this)'>{.!Change password.}</button>
            .}
            :}
            | 
            <form method='post' onsubmit='return login()'>
                <table>
                <tr><td align='right'>{.!Username.}<td><input name='__USER' size='15' /><p>
                <tr class='hideThis'><td align='right'>{.!Password.}<td><input name='__PASSWORD' size='15' type='password' />
                <tr class='hideThis'><td><td><input type='submit' value='{.!Login.}'>
                </table>
            </form>
        .}
		</center>
	</fieldset>                                       

	<fieldset id='folder'>
		<legend><img src="/~img8"> {.!Folder.}</legend>

       <div style='float:right; position:relative; top:-1em; font-weight:bold;'>
		{.if| {.?search.} | <a href="."><img src="/~img14"> {.!Back.}</a> 
		| {.if| {.%folder% != / .} | <a href=".."><img src="/~img14"> {.!Up.}</a> .}
		/if.}
		</div>

		<div id='breadcrumbs'>
		{.comment|we need this to start from 1 {.count|folder levels.}.}        
		{.breadcrumbs|{:<a href="%bread-url%" {.if|%bread-name%|style='padding-left:{.calc|{.count|folder levels.}*0.7.}em;'.} /> {.if|%bread-name%|&raquo; %bread-name%|<img src="/~img1"> {.!Home.}.}</a>:} .}
       </div>
        
		<div id='folder-stats'>%number-folders% {.!folders.}, %number-files% {.!files.}, {.add bytes|%total-size%.}
		</div>
		
		{.123 if 2| <div id='foldercomment'>|{.commentNL|%folder-item-comment%.}|</div> .}
	</fieldset>
	
	{.if| {.get|can recur.} |
	<fieldset id='search'>
		<legend><img src="/~img3"> {.!Search.}</legend>
		<form style='text-align:center'>
			<input name='search' size='15' value="{.escape attr|{.?search.}.}">
			<input type='submit' value="{.!go.}">
		</form>
		<div style='margin-top:0.5em;' class='hidden popup'>
			<fieldset>
				<legend>{.!Where to search.}</legend>
					<input type='radio' name='where' value='fromhere' checked='true' />  {.!this folder and sub-folders.}
					<br><input type='radio' name='where' value='here' />  {.!this folder only.}
					<br><input type='radio' name='where' value='anywhere' />  {.!entire server.}
			</fieldset>
		</div>
	</fieldset>
	/if.}
	
	<fieldset id='select' class='onlyscript'>
		<legend><img src="/~img15"> {.!Select.}</legend>
		<center>
    	<button onclick='
           var x = $("#files .selectable");
			if (x.size() > x.filter(".selected").size())
				x.addClass("selected")
			else
				x.removeClass("selected");
			selectedChanged();
			'>{.!All.}</button>
    	<button onclick='
           $("#files .selectable").toggleClass("selected");
			selectedChanged();
			'>{.!Invert.}</button>
    	<button onclick='selectionMask.call(this)'>{.!Mask.}</button>
		<p style='display:none; margin-top:1em;'><span id='selected-number'>0</span> items selected</p>
		</center>
	</fieldset>
	
	{.if| {.get|can upload.} |{:
		<fieldset id='upload'>
    		<legend><img src="/~img32"> {.!Upload.}</legend>
    		<form action="." method='post' enctype="multipart/form-data" style='text-align:right;'>
    		<input type='file' name='file' style='display:block;' />
    		<input type='submit' value='{.!Upload.}' style='margin-top:0.5em;' />
    		</form>
		</fieldset>
	:}.}
	
	<fieldset id='actions'>
		<legend><img src="/~img18"> {.!Actions.}</legend>
		<center>
		{.if|{.can mkdir.}|
		<button onclick='ezprompt(this.innerHTML, {type:"text"}, function(s){
				$.post("?mode=section&id=ajax.mkdir", {"name":s}, getStdAjaxCB());
		    });'>{.!New folder.}</button>
		.}
		{.if|{.can comment.}|
		<button onclick='setComment.call(this)'>{.!Comment.}</button>
		.}
		{.if|{.get|can delete.}|
		<button onclick='if (confirm("{.!confirm.}")) submit("", {action:"delete"}, true)'>{.!Delete.}</button>

		{.if|{.and|{.!option.move.}|{.can move.}.}| <button onclick='moveClicked()'>{.!Move.}</button> .}
		.}
		{.if|{.can rename.}|
		<button id='renameBtn' onclick='
			var el = $("#files .selected .the-item");
			if (el.size() != 1)
				return alert("You must select a single item to rename");
			ezprompt(this.innerHTML, {type:"text"}, function(s){
				$.post("?mode=section&id=ajax.rename", {"from":getItemName(el), "to":s}, getStdAjaxCB());
		    });'>{.!Rename.}</button>
		.}
		{.if|{.get|can archive.}|
		<button onclick='if (confirm("{.!confirm.}")) submit("{.get|url|mode=archive|recursive.}", {}, true)'>{.!Archive.}</button>
		.}				
		<a href="{.get|url|tpl=list|sort=|{.if not|{.?search.}|{:folders-filter=\|recursive:}.}.}">{.!Get list.}</a>
		</center>
	</fieldset>

	<fieldset id='serverinfo'>
		<legend><img src="/~img0"> {.!Server information.}</legend>
		<a href="http://www.rejetto.com/hfs/">HttpFileServer %version%</a>
		<br />{.!Server time.}: %timestamp%
		<br />{.!Server uptime.}: %uptime%
	</fieldset>
	
</div>

<div style='height:100%; overflow:auto; text-align:left; padding:0 1.6em;'>
	<div style='height:1.6em;'>
		{.comment| this is quite ugly, i know, but if i use any vertical padding with height:100% i'll get a scrollbar .}
	</div> 
	{.if not| %number% |{: <div style='font-size:200%; padding:1em;'>{.!No {.if|{.?search.}|results|files.}.}</div> :}|{:
		<table id='files'>
		{.set|sortlink| {:<a href="{.trim|
				{.get|url|sort=$1| {.if| {.{.?sort.} = $1.} |  rev={.not|{.?rev.} .} /if.} /get.}
			/trim.}">{.!$2.}{.if| {.{.?sort.} = $1.} | &{.if|{.?rev.}|u|d.}arr;.}</a>:} .}
		<th>{.^sortlink|n|Filename.}{.^sortlink|e|.ext.}
		<th>{.^sortlink|s|Filesize.}
		<th>{.^sortlink|t|Filetime.}
		<th>{.^sortlink|d|Hits.}
		%list%
		</table>
	:}.}
</div>

</body>
</html>
<!-- Build-time: %build-time% -->

[+special:strings]
max s dl msg=There is a limit on the number of <b>simultaneous</b> downloads on this server.<br>This limit has been reached. Retry later.
retry later=Please, retry later.
item folder=in folder
no files=No files in this folder
no results=No items match your search query
confirm=Are you sure?

[style.css|no log]
body { font-family:tahoma, verdana, arial, helvetica, sans; font-weight:normal; font-size:9pt; background-color:#eef; }
html, body { padding:0; border:0; height:100%; }
html, body, p, form { margin:0 }
a { text-decoration:none; color:#47c; border:1px solid transparent; padding:0 0.1em; }
a:visited { color:#55F; }
a:hover { background-color:#fff; border-color:#47c; }
img { border-style:none }
fieldset { margin-bottom:0.7em; text-align:left; padding:0.6em; }

#panel { float:left; margin-top:1em; margin-left:1em; max-width:250px; }
#panel hr { width:80%; margin:1em auto; }                              
#files { background:#ddf; border:0; }
#files tr { background:#fff; }
#files tr.even { background:#eef; }
#files tr.selected { background:#bcf; }
#files td { padding:0.2em 0.5em; text-align:right; }
#files tr td:first-child { text-align:left; }
#files th { padding:0.5em 1em; background:#47c; text-align:center; }
#files th a { color:white; font-size:130%; }
#files th a:hover { background:transparent; border-color:#fff; color:#fff; font-size:130%; }
#files td:first-child { text-align:left; padding-left:1.5em; } /* extra space for easy selection */
#files td.nosize { text-align:center; font-style:italic; }
#actions button { margin:0.2em; } 
#breadcrumbs { margin-top:1em; padding-left:0.5em; }
#breadcrumbs a { padding:0.15em 0; border-width:2px; display:block; }
#folder-stats, #foldercomment { margin-top:1em; padding-top:0.5em; border-top:1px solid #666;  }
#folder-stats { color:#666; text-align:center; }
#msgs { display:none; }
#msgs li:first-child { font-weight:bold; }
#pages span { padding-left:0.5em; padding-right:0.5em; cursor:pointer; }
#pages button, #login button { font-size:smaller; }
.selectedPage { font-weight:bold; font-size:larger; }
.hidden { display:none; }
                             
[file=folder=link|private]
	<tr class='{.if not|{.or|{.get|can delete.}|{.get|can access.}|{.get|can archive item.}.}|non.}selectable {.if|{.mod|{.count|row.}|2.}|even.}'><td>
		{.if|{.get|is new.}|<span class='flag'>&nbsp;NEW&nbsp;</span>.}
		{.if not|{.get|can access.}|<img src='/~img_lock'>.}
		<a class='the-item' href="%item-url%"><img src="%item-icon%"> %item-name%</a>
		{.if| {.?search.} |{:{.123 if 2|<div class='item-folder'>{.!item folder.} |{.breadcrumbs|{:<a href="%bread-url%">%bread-name%/</a>:}|from={.count substring|/|%folder%.}/breadcrumbs.}|</div>.}:} .}
		{.123 if 2|<div class='comment'>|{.commentNL|%item-comment%.}|</div>.}

[+file]
<td>%item-size%B<td>%item-modified%<td>%item-dl-count%

[+folder]
<td class='nosize'>folder<td>%item-modified%<td>%item-dl-count%

[+link]
<td class='nosize'>link<td colspan='2'>

[error-page]
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN">
<html>
  <head>
  <meta http-equiv="content-type" content="text/html; charset=UTF-8">
  <style type="text/css">
  {.$style.css.}
  </style>
  </head>
<body>
%content%
<hr>
<div style="font-family:tahoma, verdana, arial, helvetica, sans; font-size:8pt;">
<a href="http://www.rejetto.com/hfs/">HttpFileServer %version%</a>
<br>%timestamp%
</div>
</body>
</html>

[not found]
<h1>{.!Not found.}</h1>
<a href="/">{.!go to root.}</a>

[overload]
<h1>{.!Server Too Busy.}</h1>
{.!The server is too busy to handle your request at this time. Retry later.}

[max contemp downloads]
<h1>{.!Download limit.}</h1>
{.!max s dl msg.}

[unauthorized]
<h1>{.!Unauthorized.}</h1>
{.!Either your user name and password do not match, or you are not permitted to access this resource..}

[deny]
<h1>{.!Forbidden.}</h1>
{.or|%reason%|{.!This resource is not accessible..}.}

[ban]
<h1>{.!You are banned.}</h1>
%reason%

[upload]

[upload-file]

[upload-results]
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN">
<html>
<head>
	<meta http-equiv="content-type" content="text/html; charset=UTF-8">
	<title>HFS %folder%</title>
	<link rel="stylesheet" href="/?mode=section&id=style.css" type="text/css">
	<style>
	li {list-style-image:url(/~img7); padding-bottom:1em; }
    li.bad { list-style-image:url(/~img11); }
	ul { border:1px solid #999; border-left:0; border-right:0; padding-top:1em; }
	a.back { display: block; width: 10em; white-space:nowrap; padding:0.3em 0.5em; margin-top:1em; }
    </style>
</head>
<body style='margin:2em;'>
<h1>{.!Upload results.}</h1>
{.^ok.} {.!files uploaded correctly..}
{.123 if 2|<br /> |{.^ko.}| files failed..}
<a href="." class='back'><img src="/~img14"> {.!Back.}</a>
{.^back.}
<ul>
%uploaded-files%
</ul>
<a href="." class='back'><img src="/~img14"> {.!Back.}</a>
</body>
</html>

[upload-success]
{.inc|ok.}
<li> <a href='%item-url%'>%item-name%</a>
<br />%item-size% @ %speed% KB/s
{.if| %user% |{: {.append| %folder-resource%\hfs.comments.txt |{.filename|%item-resource%.}=uploaded by %user%
/append.} :}/if.}

[upload-failed]
{.inc|ko.}
<li class='bad'>%item-name%
<br />{.!%reason%.}

[progress|no log]
<style>
#progress .fn { font-weight:bold; }
.out_bar { margin-top:0.25em; width:100px; font-size:15px; background:#fff; border:#555 1px solid; margin-right:5px; float:left; }
.in_bar { height:0.5em; background:#47c;  }
</style>
<ul style='padding-left:1.5em;'>
%progress-files%
</ul>

[progress-nofiles]
{.!No file exchange in progress..}

[progress-upload-file]
{.if not|{.{.?only.} = down.}|{:
	<li> Uploading %total% @ %speed-kb% KB/s
	<br /><span class='fn'>%filename%</span>
	<br>
	<div class='out_bar'><div class='in_bar' style="width:%perc%px"></div></div> %perc%%
:}.}

[progress-download-file]
{.if not|{.{.?only.} = up.}|{:
	<li> Downloading %total%
	<br>Speed: %speed-kb% KB/s
	<br /><span class='fn'>%filename%</span>
	<br>
	<div class='out_bar'><div class='in_bar' style="width:%perc%px"></div></div> %perc%%
:}.}

[ajax.mkdir|no log]
{.break|if={.not|{.can mkdir.}.}|result=forbidden.}
{.set|x|{.force ansi|%folder%{.postvar|name.}.}.}
{.break|if={.exists|{.^x.}.}|result=exists.}
{.break|if={.not|{.length|{.mkdir|{.^x.}.}.}.}|result=failed.}
{.add to log|User %user% created folder "{.^x.}".}
ok

[ajax.rename|no log]
{.break|if={.not|{.can rename.}.}|result=forbidden.}
{.set|x|{.force ansi|%folder%{.postvar|from.}.}.}
{.set|y|{.force ansi|%folder%{.postvar|to.}.}.}
{.break|if={.not|{.exists|{.^x.}.}.}|result=not found.}
{.break|if={.exists|{.^y.}.}|result=exists.}
{.break|if={.not|{.length|{.rename|{.^x.}|{.^y.}.}.}.}|result=failed.}
{.add to log|User %user% renamed "{.^x.}" to "{.^y.}".}
ok

[ajax.move|no log]
{.set|dst|{.force ansi|{.postvar|dst.}.}.}
{.break|if={.not|{.and|{.can move.}|{.get|can delete.}|{.get|can upload|path={.^dst.}.}/and.}.} |result={.!forbidden.}.}
{.set|log|{.!Moving items to.} {.^dst.}.}
{.for each|fn|{.force ansi|{.replace|:|{.no pipe||.}|{.postvar|files.}.}.}|{:
    {.set|x|{.force ansi|%folder%.}{.^fn.}.}
    {.set|y|{.^dst.}/{.^fn.}.}
    {.if not |{.exists|{.^x.}.}|{.^x.}: {.!not found.}|{:
        {.if|{.exists|{.^y.}.}|{.^y.}: {.!already exists.}|{:
            {.if|{.length|{.move|{.^x.}|{.^y.}.}.} |{: 
                {.set|log|{.chr|13.}{.^fn.}|mode=append.}
                {.move|{.^x.}.md5|{.^y.}.md5.}
                {.move|{.^x.}.comment|{.^y.}.comment.}
            :} | {:
                {.set|log|{.chr|13.}{.^fn.} (failed)|mode=append.}
                {.maybe utf8|{.^fn.}.}: {.!not moved.}
            :}/if.}
        :}/if.}
    :}.}
    ;
:}.}
{.add to log|{.^log.}.}

[ajax.comment|no log]
{.break|if={.not|{.can comment.}.} |result=forbidden.}
{.for each|fn|{.replace|:|{.no pipe||.}|{.postvar|files.}.}|{:
    {.set item|{.force ansi|%folder%{.^fn.}.}|comment={.force ansi|{.postvar|text.}.}.}
:}.}
ok

[ajax.changepwd|no log]
{.break|if={.not|{.can change pwd.}.} |result=forbidden.}
{.if|{.length|{.set account||password={.force ansi|{.postvar|new.}.}.}/length.}|ok|failed.}

[special:alias|private]
can mkdir=and|{.get|can upload.}|{.!option.newfolder.}
can comment=and|{.get|can upload.}|{.!option.comment.}
can rename=and|{.get|can delete.}|{.!option.rename.}
can change pwd=member of|can change password
can move=or|1
escape attr=replace|"|&quot;|$1
commentNL=if|{.pos|<br|$1.}|$1|{.replace|{.chr|10.}|<br />|$1.}
add bytes=switch|{.cut|-1||$1.}|,|0,1,2,3,4,5,6,7,8,9|$1 bytes|K,M,G,T|$1bytes

[special:import|private]
{.new account|can change password|enabled=1|is group=1|notes=accounts members of this group will be allowed to change their password.}

[lib.js|no log]
// <script> // this is here for the syntax highlighter

function login() {
    if (typeof MD5 == 'undefined') return true; // we got no md5 lib, let the form act normally
    var sid = getCookie('HFS_SID');
    if (!sid) return true;
    var usr = $('#login [name=__USER]').val();
    var pwd = $('#login [name=__PASSWORD]').val();
    var hash = MD5(MD5(pwd).toUpperCase()+sid).toUpperCase();
    $.post('', { '__USER':usr, '__PASSWORD_MD5':hash, '__AJAX':1 }, getStdAjaxCB());
    return false;
} // login

function logout() {
    $.post('', { '__USER':'', '__AJAX':1 }, getStdAjaxCB());
} // logout

function outsideV(e, additionalMargin) {
    outsideV.w || (outsideV.w = $(window));
    if (!(e instanceof $))
        e = $(e);
    return e.offset().top + e.height() > outsideV.w.height() - (additionalMargin || 0) - 15;
} // outsideV

$(function(){
    // make these links into buttons for homogeneity
    $('#actions a').replaceWith(function(){ return "<button onclick='location = \""+this.getAttribute('href')+"\"'>"+this.innerHTML+"</button>"; });
    // selecting functionality
    $('#files tr.selectable').click(function( ){
        $(this).toggleClass('selected');
        selectedChanged();
    });
    $('#files tr.nonselectable').click(function(){
        putMsg("{.!You cannot select this item.}");
    });
    
    $('#login .hideThis').hide();
    $('#login input:first').focusin(function(){ $('#login :hidden').fadeIn(); });

    $('.trash-me').detach(); // this was hiding things for those w/o js capabilities
    // infinite upload fields available
    var x = $('input[type=file]');
    x.change(function(){
        if ($(this).data('fired')) return;
        $(this).data('fired',1);
        fileTpl.clone(true).insertAfter(this).css('display','block');
    });
    // we must create an empty "template", by cloning before it's set to a file, because on some browsers (Opera 10) emptying the value run-time is not allowed.
    // this must be done after the above instruction, so we'll clone also the behavior. 
    var fileTpl = x.clone(true).css('display','none');

    var x = $('#upload');
    if  (x.size()) {
        // make it popup by button, so we save some vertical space and avoid some scrollbar
        x.hide(); 
        $('#actions button:first').before(
            $("<button>{.!Upload.}</button>").click(function(){ 
                $(this).slideUp(); x.fadeIn(); 
            })
        );
        // on submit			
        x.find('form').submit(function(){ 
            if (!$("[name=file]").val()) return false; // no file, no submit
            $(this).hide(); // we don't need the form anymore, make space for the progress bars
            // build the gui
            x.append("<div id='progress'>in progress...</div>");
            x.append($("<button style='float:right'>{.!Cancel.}</button>").click(function(){
                // stop submit/upload
                if (typeof stop == 'function')
                    stop(); 
                else
                    document.execCommand("Stop");
                $(this).add($("#progress")).remove(); // remove progress indicators and this button too
                $("#upload form").slideDown(); // re-show the form
            }));

            // refresh information
            function updateProgress() {
                $.get('/?mode=section&id=progress&only=up', function(txt) {
                    var x = $('#progress');
                    if (!x.size()) return;
                    if (txt.indexOf('<li>') >= 0) x.html(txt);
                    setTimeout(updateProgress, 3000);
                });
            }//updateProgress
            updateProgress();
            return true;
        });
    }

    // search options appear when it gets focus
    $('#search').focusin(function(evt){
        inSearch = 1;
        if (evt.target.getAttribute('type') == 'submit') return; // the submitter button won't expand the popup, but sets the flag to avoid the popup to be closed
        $("#search .popup").slideDown();
    }).focusout(function(evt){
        inSearch = 0;
        setTimeout(function(){
            if (!inSearch)
                $("#search .popup").fadeOut();
        });
    });
    $('#search form').submit(function(){
        var s = $(this).find('[name=search]').val();
        var a = '';
        var ps = [];
        switch ($('[name=where]:checked').val()) {
            case 'anywhere': 
                a = '/';
            case 'fromhere':
                ps.push('search='+s);
                break;
            case 'here':
                if (s.indexOf('*') < 0) s = '*'+s+'*';
                ps.push('files-filter='+s);
                ps.push('folders-filter='+s);
                break;
        }
        location = a+'?'+ps.join('&');
        return false;
    });
    
    // workaround for those browsers not supporting :first-child selector
    if ($('#files td:first').css('text-align') != 'left')
        $('#files tr td:first-child').css('text-align','left');

    // here we make some changes trying to make the panel fit the window
    var removed = 0;
    var e = $('#panel'); 
    while (outsideV(e)) {
        switch (++removed) {
            case 1: $('#serverinfo').hide(); continue;
            case 2: $('#select').hide(); continue;
            case 3: $('#breadcrumbs a').css({display:'inline',paddingLeft:0}); continue;
            case 4: $('#login').replaceWith($('#login center').prepend('<img src="/~img27">')); continue;
        }
        break; // give up
    }
    if (HFS.paged)
        if (getCookie('paged') == 'no')
            addPagingButton('#actions button:first');
        else
            pageIt();
           
           
    {.$more onload.}
    selectedChanged();
    // darn you ie6!
    if (!$.browser.msie || $.browser.version > 6) return;
    $('fieldset').width('250px').after('<br>');
    $('#panel').css('margin-right','1.5em');
    $('a').css('border-width','0');
});//onload

function addPagingButton(where) {
    $("<button>{.!Paged list.}</button>").insertBefore(where || '#files').click(function(){
        $(this).remove();
        pageIt(true);
        delCookie('paged');
    });
}//addPagingButton

function pageIt(anim) {
    var rows = $('#files tr');
    if (!rows.size()) return;
    
    page = 0; // this is global
    var pages = $("<div id='pages'>{.!Page.} </div>").css('visibility','hidden').insertBefore('#files');
    var pageSize = 0;
    while (!outsideV(rows[pageSize], 20))
        if (++pageSize >= rows.size())
            return pages.remove();

    Npages = Math.ceil(HFS.number / pageSize);
    if (Npages == 1)
        return pages.remove();
    $('#files').width($('#files').width()); // hold it still

    var s = '';
    for (var i=1; i <= Npages; i++)
        s += '<span>'+i+'</span> ';
    s = $(s);
    s.appendTo(pages).click(function(){
        page = Number(this.innerHTML)-1;
        $('#files tr:gt(0):visible').hide();
        $('#files tr:gt('+(page*pageSize)+'):lt('+pageSize+')').show();
        pages.find('span').removeClass('selectedPage').filter(':nth('+page+')').addClass('selectedPage');
    });
    s.first().addClass('selectedPage');		
    $('#files tr:gt('+((page+1)*pageSize)+')').hide();
    pages.append($('<button>{.!No pages.}</button>').click(function(){
        pages.slideUp(function(){ pages.remove(); });
        $('#files tr:hidden').show();
        addPagingButton();
        setCookie('paged', 'no');
    }));
    pages.css({'visibility':'', 'display':'none'});
    if (anim) pages.slideDown()
    else pages.show();		
}//pageIt

function selectedChanged() {
    $("#selected-number").text( $("#files .selected").size() ).parent().show();
} // selectedChanged

function getItemName(el) {
    if (typeof el == 'undefined')
        return false;
    // we handle elements, not jquery sets  
    if (el.jquery)
        if (el.size())
            el = el[0];
        else
            return false;
    // take the url, and ignore any #anchor part
    var s = el.getAttribute('href').split('#')[0];
    // remove protocol and hostname
    var i = s.indexOf('://');
    if (i > 0)
        s = s.slice(s.indexOf('/',i+3));
    // current folder is specified. Remove it.
    if (s.indexOf(HFS.folder) == 0)
        s = s.slice(HFS.folder.length);
    // folders have a trailing slash that's not truly part of the name
    if (s.slice(-1) == '/')
        s = s.slice(0,-1);
    // it is encoded
    s = (decodeURIComponent || unescape)(s);        
    return s;
} // getItemName

function submit(url, data, selection) {
    // create the form
    var x = $("<form method='post' action='"+url+"' />").appendTo($('body'));
    for (var k in data)
        x.append("<input type='hidden' name='"+k+"' value='"+data[k]+"' />");
    if (selection)
        $("#files .selected .the-item").each(function(){  
            x.append('<input type="hidden" name="selection" value="'+getItemName(this)+'" />');
        });			
    // submit and discard
    x.submit().detach();
}//submit

function putMsg(txt, time) {
    if (!time) time = 4000;
    var msgs = $('#msgs');
    msgs.slideDown();
    if (msgs.find('ul li:first').html() == txt)
        clearTimeout(lastTimeoutID);
    else
        msgs.find('ul').prepend("<li>"+txt+"</li>");
    lastTimeoutID = setTimeout("$('#msgs li:last').fadeOut(function(){$(this).detach(); if (!$('#msgs li').size()) $('#msgs').slideUp(); });", time);
}//putMsg

RegExp.escape = function(text) {
    if (!arguments.callee.sRE) {
        var specials = '/.*+?|()[]{}\\'.split('');
        arguments.callee.sRE = new RegExp('(\\' + specials.join('|\\') + ')', 'g');
    }
    return text.replace(arguments.callee.sRE, '\\$1');
}//escape

function include(url, type) {
    $.ajaxSetup({async: false}); // we'll wait.
    if (!type)
        type = /[^.]+$/.exec(url);
    var res;
    if  (type == 'js')
        res = $.getScript(url);
    else res = $.get(url, function(){ 
        if (type == 'css')
            $('head').append('<link rel="stylesheet" href="'+url+'" type="text/css" />');
    });
    $.ajaxSetup({async: true}); // restore it
    return res.responseText;
}//include

function ezprompt(msg, options, cb) {
    // 2 parameters means "options" is missing
    if (ezprompt.arguments.length == 2) {
        cb = options;
        options = {};
    }
    if (!$.prompt) { // load on demand
        include('/?mode=section&id=impromptu.css');
        include('/?mode=section&id=jquery.impromptu.js'); 
    }
    var v;
    if (v = options.type) {
        msg += '<br />';
        if (v == 'textarea')
            msg += '<textarea name="txt" cols="30" rows="8">'+options['default']+'</textarea>';
        else
            msg += '<input name="txt" type="'+v+'"'
                + ((v = options['default']) ? ' value="'+v+'"' : '')
                + ' />';
    }
    $.prompt(msg, {
        opacity: 0.9,
        overlayspeed: 'fast',
        loaded: function(){  
            $('#jqibox').find(':input').keypress(function (e) {
                var c = (e.keyCode || e.which);
                if (options.keypress && options.keypress(c, this, e) === false) return;
                if (c != 13 || this.tagName == 'TEXTAREA') return; // ENTER key is like submit, but not in textarea
                $('.jqibuttons button:first').click();
                return false;
            }).filter(':first').focus()[0].select(); 
        },
        submit: function(val,div,form) {
            var res = cb(options.type ? form.txt : form, $('#jqibox'), options.cbData );
            if (res === false) {
                $('#jqibox').find(':input:first').focus();
                return false;
            }
            return true;                        
        }, 
        fadeClicked: function() { $('#jqibox').find(':input:first').focus(); }
    });
}//ezprompt

// this is a factory for ajax request handlers
function getStdAjaxCB(what2do) {
    if (!arguments.length)
        what2do = true;
    return function(res){
        res = $.trim(res);
        if (res != "ok")
            return alert("{.!Error.}: "+res);
        // what2do is a list of actions we are supposed to do if the ajax result is "ok"
        if (typeof what2do == 'undefined') 
            return;            
        if (!$.isArray(what2do))
            what2do = [what2do];
        for (var i=0; i<what2do.length; i++) {
            var w = what2do[i];
            switch (typeof w) {
                case 'function': w(); break; // you specify exactly what to do
                case 'string':
                    switch (w[0]) {
                        case '!': alert(w.substr(1)); break;
                        case '>': location = w.substr(1); break;
                        default: putMsg(w); break;
                    }
                case 'boolean': if (w) location = location; break;
            }
        }
    }
}//getStdAjaxCB
        
function changePwd() {
    ezprompt(this.innerHTML, {"type":"password"}, function(s){
        if (s) $.post("?mode=section&id=ajax.changepwd", {"new":s}, getStdAjaxCB([
            "!{.!Password changed, you\'ll have to login again..}", 
            '>~login'
        ]));
    });
}//changePwd

function selectedFilesAsStr() {
    var a = [];
    $("#files .selected .the-item").each(function(){
        a.push(getItemName(this));
    });
    return a.join(":");
}//selectedFilesAsStr

function setComment() {
    var n = $("#files .selected").size();
    if (!n)
        return putMsg("{.!No file selected.}");
    var x = $("#files .selected .comment");
    var def = (x.size() ? x.html() : '');
    ezprompt(this.innerHTML, {"type":"textarea", "default":def}, function(s){
        if (s == def && n == 1) return; // there s no work to do
        $.post("?mode=section&id=ajax.comment", {"text":s, "files":selectedFilesAsStr()}, getStdAjaxCB());
    });
}//setComment

function moveClicked() {
    ezprompt("{.!Enter the destination folder.}", {type:"text"}, function(s){
        $.post("?mode=section&id=ajax.move", {"dst":s, files:selectedFilesAsStr()}, function(res){
            var a = res.split(";");
            if (a.length < 2)
                return alert($.trim(res));
            var failed = 0;
            var ok = 0;
            var msg = "";
            for (var i=0; i<a.length-1; i++) {
                var s = $.trim(a[i]);
                if (!s.length) {
                    ok++;
                    continue;
                }
                failed++;
                msg += s+"\n";
            }
            if (failed) 
                msg = "{.!We met the following problems:.}\n"+msg;
            msg = (ok ? ok+" {.!files were moved..}\n" : "{.!No file was moved..}\n")+msg;
            alert(msg);
            if (ok) location = location; // reload
        });
    });
}//moveClicked

function selectionMask() {
    ezprompt("{.!Please enter the file mask to select.}", {"type":"text", "default":"*"}, function(s){
        if (!s) return false;
        var re = s.match("^/([^/]+)/([a-zA-Z]*)");
        if (re)
            re = new RegExp(re[1], re[2]);
        else {
            var n = s.match(/^(\\*)/)[0].length;
            s = s.substring(n);
            var invert = !!(n % 2); // a leading "\" will invert the logic
            s = RegExp.escape(s).replace(/[?]/g,".");;
            if (s.match(/\\\*/)) {
                s = s.replace(/\\\*/g,".*");
                s = "^ *"+s+" *$";   // in this case let the user decide exactly how it is placed in the string  
            }
            re = new RegExp(s, "i");
        }
        $("#files .selectable .the-item")
            .filter(function(){ return invert ^ re.test(getItemName(this)); })
            .closest(".selectable").addClass("selected");
        selectedChanged();
    }); 
}//selectionMask

function setCookie(name,value,days) {
	if (days) {
		var date = new Date();
		date.setTime(date.getTime()+(days*24*60*60*1000));
		var expires = "; expires="+date.toGMTString();
	}
	else var expires = "";
	document.cookie = name+"="+value+expires+"; path=/";
} // setCookie

function getCookie(name) {    
    var a = document.cookie.match(new RegExp('(^|;\s*)('+name+'=)([^;]*)'));
    return (a && a[2]) ? a[3] : null;
} // getCookie

function delCookie(name) {
	setCookie(name,"",-1);
} // delCookie

    
[jquery.impromptu.js|no log]
/*
 * jQuery Impromptu
 * By: Trent Richardson [http://trentrichardson.com]
 * Version 2.7
 * Last Modified: 6/7/2009
 * 
 * Copyright 2009 Trent Richardson
 * Dual licensed under the MIT and GPL licenses.
 * http://trentrichardson.com/Impromptu/GPL-LICENSE.txt
 * http://trentrichardson.com/Impromptu/MIT-LICENSE.txt
 * 
 */
 
(function($) {
	$.prompt = function(message, options) {
		options = $.extend({},$.prompt.defaults,options);
		$.prompt.currentPrefix = options.prefix;

		var ie6		= ($.browser.msie && $.browser.version < 7);
		var $body	= $(document.body);
		var $window	= $(window);

		//build the box and fade
		var msgbox = '<div class="'+ options.prefix +'box" id="'+ options.prefix +'box">';
		if(options.useiframe && (($('object, applet').length > 0) || ie6)) {
			msgbox += '<iframe src="javascript:false;" style="display:block;position:absolute;z-index:-1;" class="'+ options.prefix +'fade" id="'+ options.prefix +'fade"></iframe>';
		} else {
			if(ie6) {
				$('select').css('visibility','hidden');
			}
			msgbox +='<div class="'+ options.prefix +'fade" id="'+ options.prefix +'fade"></div>';
		}
		msgbox += '<div class="'+ options.prefix +'" id="'+ options.prefix +'"><div class="'+ options.prefix +'container"><div class="';
		msgbox += options.prefix +'close">X</div><div id="'+ options.prefix +'states"></div>';
		msgbox += '</div></div></div>';

		var $jqib	= $(msgbox).appendTo($body);
		var $jqi	= $jqib.children('#'+ options.prefix);
		var $jqif	= $jqib.children('#'+ options.prefix +'fade');

		//if a string was passed, convert to a single state
		if(message.constructor == String){
			message = {
				state0: {
					html: message,
				 	buttons: options.buttons,
				 	focus: options.focus,
				 	submit: options.submit
			 	}
		 	};
		}

		//build the states
		var states = "";

		$.each(message,function(statename,stateobj){
			stateobj = $.extend({},$.prompt.defaults.state,stateobj);
			message[statename] = stateobj;

			states += '<div id="'+ options.prefix +'_state_'+ statename +'" class="'+ options.prefix + '_state" style="display:none;"><div class="'+ options.prefix +'message">' + stateobj.html +'</div><div class="'+ options.prefix +'buttons">';
			$.each(stateobj.buttons, function(k, v){
				states += '<button name="' + options.prefix + '_' + statename + '_button' + k + '" id="' + options.prefix +	'_' + statename + '_button' + k + '" value="' + v + '">' + k + '</button>';
			});
			states += '</div></div>';
		});

		//insert the states...
		$jqi.find('#'+ options.prefix +'states').html(states).children('.'+ options.prefix +'_state:first').css('display','block');
		$jqi.find('.'+ options.prefix +'buttons:empty').css('display','none');
		
		//Events
		$.each(message,function(statename,stateobj){
			var $state = $jqi.find('#'+ options.prefix +'_state_'+ statename);

			$state.children('.'+ options.prefix +'buttons').children('button').click(function(){
				var msg = $state.children('.'+ options.prefix +'message');
				var clicked = stateobj.buttons[$(this).text()];
				var forminputs = {};

				//collect all form element values from all states
				$.each($jqi.find('#'+ options.prefix +'states :input').serializeArray(),function(i,obj){
					if (forminputs[obj.name] === undefined) {
						forminputs[obj.name] = obj.value;
					} else if (typeof forminputs[obj.name] == Array) {
						forminputs[obj.name].push(obj.value);
					} else {
						forminputs[obj.name] = [forminputs[obj.name],obj.value];	
					} 
				});

				var close = stateobj.submit(clicked,msg,forminputs);
				if(close === undefined || close) {
					removePrompt(true,clicked,msg,forminputs);
				}
			});
			$state.find('.'+ options.prefix +'buttons button:eq('+ stateobj.focus +')').addClass(options.prefix +'defaultbutton');

		});

		var ie6scroll = function(){
			$jqib.css({ top: $window.scrollTop() });
		};

		var fadeClicked = function(){
			if(options.persistent){
			    if (options.fadeClicked() === false) return; // mod by rejetto
				var i = 0;
				$jqib.addClass(options.prefix +'warning');
				var intervalid = setInterval(function(){
					$jqib.toggleClass(options.prefix +'warning');
					if(i++ > 1){
						clearInterval(intervalid);
						$jqib.removeClass(options.prefix +'warning');
					}
				}, 100);
			}
			else {
				removePrompt();
			}
		};
		
		var keyPressEventHandler = function(e){
			var key = (window.event) ? event.keyCode : e.keyCode; // MSIE or Firefox?
			
			//escape key closes
			if(key==27) {
				removePrompt();	
			}
			
			//constrain tabs
			if (key == 9){
				var $inputels = $(':input:enabled:visible',$jqib);
				var fwd = !e.shiftKey && e.target == $inputels[$inputels.length-1];
				var back = e.shiftKey && e.target == $inputels[0];
				if (fwd || back) {
				setTimeout(function(){ 
					if (!$inputels)
						return;
					var el = $inputels[back===true ? $inputels.length-1 : 0];

					if (el)
						el.focus();						
				},10);
				return false;
				}
			}
		};
		
		var positionPrompt = function(){
			$jqib.css({
				position: (ie6) ? "absolute" : "fixed",
				height: $window.height(),
				width: "100%",
				top: (ie6)? $window.scrollTop() : 0,
				left: 0,
				right: 0,
				bottom: 0
			});
			$jqif.css({
				position: "absolute",
				height: $window.height(),
				width: "100%",
				top: 0,
				left: 0,
				right: 0,
				bottom: 0
			});
			$jqi.css({
				position: "absolute",
				top: options.top,
				left: "50%",
				marginLeft: (($jqi.outerWidth()/2)*-1)
			});
		};

		var stylePrompt = function(){
			$jqif.css({
				zIndex: options.zIndex,
				display: "none",
				opacity: options.opacity
			});
			$jqi.css({
				zIndex: options.zIndex+1,
				display: "none"
			});
			$jqib.css({
				zIndex: options.zIndex
			});
		};

		var removePrompt = function(callCallback, clicked, msg, formvals){
			$jqi.remove();
			//ie6, remove the scroll event
			if(ie6) {
				$body.unbind('scroll',ie6scroll);
			}
			$window.unbind('resize',positionPrompt);
			$jqif.fadeOut(options.overlayspeed,function(){
				$jqif.unbind('click',fadeClicked);
				$jqif.remove();
				if(callCallback) {
					options.callback(clicked,msg,formvals);
				}
				$jqib.unbind('keypress',keyPressEventHandler);
				$jqib.remove();
				if(ie6 && !options.useiframe) {
					$('select').css('visibility','visible');
				}
			});
		};

		positionPrompt();
		stylePrompt();
		
		//ie6, add a scroll event to fix position:fixed
		if(ie6) {
			$window.scroll(ie6scroll);
		}
		$jqif.click(fadeClicked);
		$window.resize(positionPrompt);
		$jqib.bind("keydown keypress",keyPressEventHandler);
		$jqi.find('.'+ options.prefix +'close').click(removePrompt);

		//Show it
		$jqif.fadeIn(options.overlayspeed);
		$jqi[options.show](options.promptspeed,options.loaded);
		$jqi.find('#'+ options.prefix +'states .'+ options.prefix +'_state:first .'+ options.prefix +'defaultbutton').focus();
		
		if(options.timeout > 0)
			setTimeout($.prompt.close,options.timeout);

		return $jqib;
	};
	
	$.prompt.defaults = {
		prefix:'jqi',
		buttons: {
			Ok: true
		},
	 	loaded: function(){

	 	},
	  	submit: function(){
	  		return true;
		},
	 	callback: function(){

	 	},
		opacity: 0.6,
	 	zIndex: 9999,
	  	overlayspeed: 'slow',
	   	promptspeed: 'fast',
   		show: 'fadeIn',
	   	focus: 0,
	   	useiframe: false,
	 	top: "15%",
	  	persistent: true,
	  	timeout: 0,
	  	state: {
			html: '',
		 	buttons: {
		 		Ok: true
		 	},
		  	focus: 0,
		   	submit: function(){
		   		return true;
		   }
	  	}
	};
	
	$.prompt.currentPrefix = $.prompt.defaults.prefix;

	$.prompt.setDefaults = function(o) {
		$.prompt.defaults = $.extend({}, $.prompt.defaults, o);
	};
	
	$.prompt.setStateDefaults = function(o) {
		$.prompt.defaults.state = $.extend({}, $.prompt.defaults.state, o);
	};
	
	$.prompt.getStateContent = function(state) {
		return $('#'+ $.prompt.currentPrefix +'_state_'+ state);
	};
	
	$.prompt.getCurrentState = function() {
		return $('.'+ $.prompt.currentPrefix +'_state:visible');
	};
	
	$.prompt.getCurrentStateName = function() {
		var stateid = $.prompt.getCurrentState().attr('id');
		
		return stateid.replace($.prompt.currentPrefix +'_state_','');
	};
	
	$.prompt.goToState = function(state) {
		$('.'+ $.prompt.currentPrefix +'_state').slideUp('slow');
		$('#'+ $.prompt.currentPrefix +'_state_'+ state).slideDown('slow',function(){
			$(this).find('.'+ $.prompt.currentPrefix +'defaultbutton').focus();
		});
	};
	
	$.prompt.nextState = function() {
		var $next = $('.'+ $.prompt.currentPrefix +'_state:visible').next();

		$('.'+ $.prompt.currentPrefix +'_state').slideUp('slow');
		
		$next.slideDown('slow',function(){
			$next.find('.'+ $.prompt.currentPrefix +'defaultbutton').focus();
		});
	};
	
	$.prompt.prevState = function() {
		var $next = $('.'+ $.prompt.currentPrefix +'_state:visible').prev();

		$('.'+ $.prompt.currentPrefix +'_state').slideUp('slow');
		
		$next.slideDown('slow',function(){
			$next.find('.'+ $.prompt.currentPrefix +'defaultbutton').focus();
		});
	};
	
	$.prompt.close = function() {
		$('#'+ $.prompt.currentPrefix +'box').fadeOut('fast',function(){
        		$(this).remove();
		});
	};
	
})(jQuery);

[impromptu.css|no log]
/*
------------------------------
	Impromptu's
------------------------------
*/
.jqifade{
	position: absolute; 
	background-color: #aaaaaa; 
}
div.jqi{ 
	min-width: 300px; 
	max-width: 600px; 
	font-family: Verdana, Geneva, Arial, Helvetica, sans-serif; 
	position: absolute; 
	background-color: #ffffff; 
	font-size: 11px; 
	text-align: left; 
	border: solid 1px #eeeeee;
	-moz-border-radius: 10px;
	-webkit-border-radius: 10px;
	padding: 7px;
}
div.jqi .jqicontainer{ 
	font-weight: bold; 
}
div.jqi .jqiclose{ 
	position: absolute;
	top: 4px; right: -2px; 
	width: 18px; 
	cursor: default; 
	color: #bbbbbb; 
	font-weight: bold; 
}
div.jqi .jqimessage{ 
	padding: 10px; 
	line-height: 20px; 
	color: #444444; 
}
div.jqi .jqibuttons{ 
	text-align: right; 
	padding: 5px 0 5px 0; 
	border: solid 1px #eeeeee; 
	background-color: #f4f4f4;
}
div.jqi button{ 
	padding: 3px 10px; 
	margin: 0 10px; 
	background-color: #2F6073; 
	border: solid 1px #f4f4f4; 
	color: #ffffff; 
	font-weight: bold; 
	font-size: 12px; 
}
div.jqi button:hover{ 
	background-color: #728A8C;
}
div.jqi button.jqidefaultbutton{ 
	/*background-color: #8DC05B;*/
	background-color: #BF5E26;
}
.jqiwarning .jqi .jqibuttons{ 
	background-color: #BF5E26;
}

/*
------------------------------
	impromptu
------------------------------
*/
.impromptuwarning .impromptu{ background-color: #aaaaaa; }
.impromptufade{
	position: absolute;
	background-color: #ffffff;
}
div.impromptu{
    position: absolute;
	background-color: #cccccc;
	padding: 10px; 
	width: 300px;
	text-align: left;
}
div.impromptu .impromptuclose{
    float: right;
    margin: -35px -10px 0 0;
    cursor: pointer;
    color: #213e80;
}
div.impromptu .impromptucontainer{
	background-color: #213e80;
	padding: 5px; 
	color: #ffffff;
	font-weight: bold;
}
div.impromptu .impromptumessage{
	background-color: #415ea0;
	padding: 10px;
}
div.impromptu .impromptubuttons{
	text-align: center;
	padding: 5px 0 0 0;
}
div.impromptu button{
	padding: 3px 10px 3px 10px;
	margin: 0 10px;
}

/*
------------------------------
	columns ex
------------------------------
*/
.colsJqifadewarning .colsJqi{ background-color: #b0be96; }
.colsJqifade{
	position: absolute;
	background-color: #ffffff;
}
div.colsJqi{
    position: absolute;
	background-color: #d0dEb6;
	padding: 10px; 
	width: 400px;
	text-align: left;
}
div.colsJqi .colsJqiclose{
    float: right;
    margin: -35px -10px 0 0;
    cursor: pointer;
    color: #bbbbbb;
}
div.colsJqi .colsJqicontainer{
	background-color: #e0eEc6;
	padding: 5px; 
	color: #ffffff;
	font-weight: bold;
	height: 160px;
}
div.colsJqi .colsJqimessage{
	background-color: #c0cEa6;
	padding: 10px;
	width: 280px;
	height: 140px;
	float: left;
}
div.colsJqi .jqibuttons{
	text-align: center;
	padding: 5px 0 0 0;
}
div.colsJqi button{
	background: url(../images/button_bg.jpg) top left repeat-x #ffffff;
	border: solid #777777 1px;
	font-size: 12px;
	padding: 3px 10px 3px 10px;
	margin: 5px 5px 5px 10px;
	width: 75px;
}
div.colsJqi button:hover{
	border: solid #aaaaaa 1px;
}

/*
------------------------------
	brown theme
------------------------------
*/
.brownJqiwarning .brownJqi{ background-color: #cccccc; }
.brownJqifade{
	position: absolute;
	background-color: #ffffff;
}
div.brownJqi{
	position: absolute;
	background-color: transparent;
	padding: 10px;
	width: 300px;
	text-align: left;
}
div.brownJqi .brownJqiclose{
    float: right;
    margin: -20px 0 0 0;
    cursor: pointer;
    color: #777777;
    font-size: 11px;
}
div.brownJqi .brownJqicontainer{
	position: relative;
	background-color: transparent;
	border: solid 1px #5F5D5A;
	color: #ffffff;
	font-weight: bold;
}
div.brownJqi .brownJqimessage{
	position: relative;
	background-color: #F7F6F2;
	border-top: solid 1px #C6B8AE;
	border-bottom: solid 1px #C6B8AE;
}
div.brownJqi .brownJqimessage h3{
	background: url(../images/brown_theme_gradient.jpg) top left repeat-x #ffffff;
	margin: 0;
	padding: 7px 0 7px 15px;
	color: #4D4A47;
}
div.brownJqi .brownJqimessage p{
	padding: 10px;
	color: #777777;
}
div.brownJqi .brownJqimessage img.helpImg{
	position: absolute;
	bottom: -25px;
	left: 10px;
}
div.brownJqi .brownJqibuttons{
	text-align: right;
}
div.brownJqi button{
	background: url(../images/brown_theme_gradient.jpg) top left repeat-x #ffffff;
	border: solid #777777 1px;
	font-size: 12px;
	padding: 3px 10px 3px 10px;
	margin: 5px 5px 5px 10px;
}
div.brownJqi button:hover{
	border: solid #aaaaaa 1px;
}

/*
*------------------------
*   clean blue ex
*------------------------
*/
.cleanbluewarning .cleanblue{ background-color: #acb4c4; }
.cleanbluefade{ position: absolute; background-color: #aaaaaa; }
div.cleanblue{ font-family: Verdana, Geneva, Arial, Helvetica, sans-serif; position: absolute; background-color: #ffffff; width: 300px; font-size: 11px; text-align: left; border: solid 1px #213e80; }
div.cleanblue .cleanbluecontainer{ background-color: #ffffff; border-top: solid 14px #213e80; padding: 5px; font-weight: bold; }
div.cleanblue .cleanblueclose{ float: right; width: 18px; cursor: default; margin: -19px -12px 0 0; color: #ffffff; font-weight: bold; }
div.cleanblue .cleanbluemessage{ padding: 10px; line-height: 20px; font-size: 11px; color: #333333; }
div.cleanblue .cleanbluebuttons{ text-align: right; padding: 5px 0 5px 0; border: solid 1px #eeeeee; background-color: #f4f4f4; }
div.cleanblue button{ padding: 3px 10px; margin: 0 10px; background-color: #314e90; border: solid 1px #f4f4f4; color: #ffffff; font-weight: bold; font-size: 12px; }
div.cleanblue button:hover{ border: solid 1px #d4d4d4; }

/*
*------------------------
*   Ext Blue Ex
*------------------------
*/
.extbluewarning .extblue{ border:1px red solid; }
.extbluefade{ position: absolute; background-color: #ffffff; }
div.extblue{ border:1px #6289B6 solid; position: absolute; background-color: #CAD8EA; padding: 0; width: 300px; text-align: left; }
div.extblue .extblueclose{ background-color: #CAD8EA; margin:2px -2px 0 0; cursor: pointer; color: red; text-align: right; }
div.extblue .extbluecontainer{ background-color: #CAD8EA; padding: 0 5px 5px 5px; color: #000000; font:normal 11px Verdana; }
div.extblue .extbluemessage{ background-color: #CAD8EA; padding: 0; margin:0 15px 15px 15px; }
div.extblue .extbluebuttons{ text-align: center; padding: 0px 0 0 0; }
div.extblue button{ padding: 1px 4px; margin: 0 10px; background-color:#cccccc; font-weight:normal; font-family:Verdana; font-size:10px; }

[md5.js|no log]
var MD5=function(j){function RotateLeft(a,b){return(a<<b)|(a>>>(32-b))}function AddUnsigned(a,b){var c,lY4,lX8,lY8,lResult;lX8=(a&0x80000000);lY8=(b&0x80000000);c=(a&0x40000000);lY4=(b&0x40000000);lResult=(a&0x3FFFFFFF)+(b&0x3FFFFFFF);if(c&lY4){return(lResult^0x80000000^lX8^lY8)}if(c|lY4){if(lResult&0x40000000){return(lResult^0xC0000000^lX8^lY8)}else{return(lResult^0x40000000^lX8^lY8)}}else{return(lResult^lX8^lY8)}}function F(x,y,z){return(x&y)|((~x)&z)}function G(x,y,z){return(x&z)|(y&(~z))}function H(x,y,z){return(x^y^z)}function I(x,y,z){return(y^(x|(~z)))}function FF(a,b,c,d,x,s,e){a=AddUnsigned(a,AddUnsigned(AddUnsigned(F(b,c,d),x),e));return AddUnsigned(RotateLeft(a,s),b)};function GG(a,b,c,d,x,s,e){a=AddUnsigned(a,AddUnsigned(AddUnsigned(G(b,c,d),x),e));return AddUnsigned(RotateLeft(a,s),b)};function HH(a,b,c,d,x,s,e){a=AddUnsigned(a,AddUnsigned(AddUnsigned(H(b,c,d),x),e));return AddUnsigned(RotateLeft(a,s),b)};function II(a,b,c,d,x,s,e){a=AddUnsigned(a,AddUnsigned(AddUnsigned(I(b,c,d),x),e));return AddUnsigned(RotateLeft(a,s),b)};function ConvertToWordArray(a){var b;var c=a.length;var d=c+8;var e=(d-(d%64))/64;var f=(e+1)*16;var g=Array(f-1);var h=0;var i=0;while(i<c){b=(i-(i%4))/4;h=(i%4)*8;g[b]=(g[b]|(a.charCodeAt(i)<<h));i++}b=(i-(i%4))/4;h=(i%4)*8;g[b]=g[b]|(0x80<<h);g[f-2]=c<<3;g[f-1]=c>>>29;return g};function WordToHex(a){var b="",WordToHexValue_temp="",lByte,lCount;for(lCount=0;lCount<=3;lCount++){lByte=(a>>>(lCount*8))&255;WordToHexValue_temp="0"+lByte.toString(16);b=b+WordToHexValue_temp.substr(WordToHexValue_temp.length-2,2)}return b};function Utf8Encode(a){a=a.replace(/\r\n/g,"\n");var b="";for(var n=0;n<a.length;n++){var c=a.charCodeAt(n);if(c<128){b+=String.fromCharCode(c)}else if((c>127)&&(c<2048)){b+=String.fromCharCode((c>>6)|192);b+=String.fromCharCode((c&63)|128)}else{b+=String.fromCharCode((c>>12)|224);b+=String.fromCharCode(((c>>6)&63)|128);b+=String.fromCharCode((c&63)|128)}}return b};var x=Array();var k,AA,BB,CC,DD,a,b,c,d;var l=7,S12=12,S13=17,S14=22;var m=5,S22=9,S23=14,S24=20;var o=4,S32=11,S33=16,S34=23;var p=6,S42=10,S43=15,S44=21;j=Utf8Encode(j);x=ConvertToWordArray(j);a=0x67452301;b=0xEFCDAB89;c=0x98BADCFE;d=0x10325476;for(k=0;k<x.length;k+=16){AA=a;BB=b;CC=c;DD=d;a=FF(a,b,c,d,x[k+0],l,0xD76AA478);d=FF(d,a,b,c,x[k+1],S12,0xE8C7B756);c=FF(c,d,a,b,x[k+2],S13,0x242070DB);b=FF(b,c,d,a,x[k+3],S14,0xC1BDCEEE);a=FF(a,b,c,d,x[k+4],l,0xF57C0FAF);d=FF(d,a,b,c,x[k+5],S12,0x4787C62A);c=FF(c,d,a,b,x[k+6],S13,0xA8304613);b=FF(b,c,d,a,x[k+7],S14,0xFD469501);a=FF(a,b,c,d,x[k+8],l,0x698098D8);d=FF(d,a,b,c,x[k+9],S12,0x8B44F7AF);c=FF(c,d,a,b,x[k+10],S13,0xFFFF5BB1);b=FF(b,c,d,a,x[k+11],S14,0x895CD7BE);a=FF(a,b,c,d,x[k+12],l,0x6B901122);d=FF(d,a,b,c,x[k+13],S12,0xFD987193);c=FF(c,d,a,b,x[k+14],S13,0xA679438E);b=FF(b,c,d,a,x[k+15],S14,0x49B40821);a=GG(a,b,c,d,x[k+1],m,0xF61E2562);d=GG(d,a,b,c,x[k+6],S22,0xC040B340);c=GG(c,d,a,b,x[k+11],S23,0x265E5A51);b=GG(b,c,d,a,x[k+0],S24,0xE9B6C7AA);a=GG(a,b,c,d,x[k+5],m,0xD62F105D);d=GG(d,a,b,c,x[k+10],S22,0x2441453);c=GG(c,d,a,b,x[k+15],S23,0xD8A1E681);b=GG(b,c,d,a,x[k+4],S24,0xE7D3FBC8);a=GG(a,b,c,d,x[k+9],m,0x21E1CDE6);d=GG(d,a,b,c,x[k+14],S22,0xC33707D6);c=GG(c,d,a,b,x[k+3],S23,0xF4D50D87);b=GG(b,c,d,a,x[k+8],S24,0x455A14ED);a=GG(a,b,c,d,x[k+13],m,0xA9E3E905);d=GG(d,a,b,c,x[k+2],S22,0xFCEFA3F8);c=GG(c,d,a,b,x[k+7],S23,0x676F02D9);b=GG(b,c,d,a,x[k+12],S24,0x8D2A4C8A);a=HH(a,b,c,d,x[k+5],o,0xFFFA3942);d=HH(d,a,b,c,x[k+8],S32,0x8771F681);c=HH(c,d,a,b,x[k+11],S33,0x6D9D6122);b=HH(b,c,d,a,x[k+14],S34,0xFDE5380C);a=HH(a,b,c,d,x[k+1],o,0xA4BEEA44);d=HH(d,a,b,c,x[k+4],S32,0x4BDECFA9);c=HH(c,d,a,b,x[k+7],S33,0xF6BB4B60);b=HH(b,c,d,a,x[k+10],S34,0xBEBFBC70);a=HH(a,b,c,d,x[k+13],o,0x289B7EC6);d=HH(d,a,b,c,x[k+0],S32,0xEAA127FA);c=HH(c,d,a,b,x[k+3],S33,0xD4EF3085);b=HH(b,c,d,a,x[k+6],S34,0x4881D05);a=HH(a,b,c,d,x[k+9],o,0xD9D4D039);d=HH(d,a,b,c,x[k+12],S32,0xE6DB99E5);c=HH(c,d,a,b,x[k+15],S33,0x1FA27CF8);b=HH(b,c,d,a,x[k+2],S34,0xC4AC5665);a=II(a,b,c,d,x[k+0],p,0xF4292244);d=II(d,a,b,c,x[k+7],S42,0x432AFF97);c=II(c,d,a,b,x[k+14],S43,0xAB9423A7);b=II(b,c,d,a,x[k+5],S44,0xFC93A039);a=II(a,b,c,d,x[k+12],p,0x655B59C3);d=II(d,a,b,c,x[k+3],S42,0x8F0CCC92);c=II(c,d,a,b,x[k+10],S43,0xFFEFF47D);b=II(b,c,d,a,x[k+1],S44,0x85845DD1);a=II(a,b,c,d,x[k+8],p,0x6FA87E4F);d=II(d,a,b,c,x[k+15],S42,0xFE2CE6E0);c=II(c,d,a,b,x[k+6],S43,0xA3014314);b=II(b,c,d,a,x[k+13],S44,0x4E0811A1);a=II(a,b,c,d,x[k+4],p,0xF7537E82);d=II(d,a,b,c,x[k+11],S42,0xBD3AF235);c=II(c,d,a,b,x[k+2],S43,0x2AD7D2BB);b=II(b,c,d,a,x[k+9],S44,0xEB86D391);a=AddUnsigned(a,AA);b=AddUnsigned(b,BB);c=AddUnsigned(c,CC);d=AddUnsigned(d,DD)}var q=WordToHex(a)+WordToHex(b)+WordToHex(c)+WordToHex(d);return q.toLowerCase()}