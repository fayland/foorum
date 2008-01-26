function emot(smilietext) {
    var input_text = document.getElementById('text');
	smilietext=' :'+smilietext+': ';
	if (input_text.createTextRange && input_text.caretPos) {
		var caretPos = input_text.caretPos;
		caretPos.text = caretPos.text.charAt(caretPos.text.length - 1) == ' ' ? smilietext + ' ' : smilietext;
		input_text.focus();
	} else {
		input_text.value += smilietext;
		input_text.focus();
	}
}

var helpstat = false;
var basic = false;
var stprompt = true;

function thelp(swtch) {
    if (swtch == 1){
        basic = false;
        stprompt = false;
        helpstat = true;
    } else if (swtch == 0) {
        helpstat = false;
        stprompt = false;
        basic = true;
    } else if (swtch == 2) {
        helpstat = false;
        basic = false;
        stprompt = true;
    }
}

function AddText(NewCode) {
    var input_text = document.getElementById('text');
    input_text.value += NewCode;
}

function showcolor(color) {
    if (helpstat) {
        alert(hpshowcolorhelppre+color+hpshowcolorhelpmid+color+hpshowcolorhelppost);
    } else if (basic) {
        AddText("[color=" + color + "][/color]");
    } else {
        txt = prompt("The color you picked is: " + color, hpText);
        if(txt != null) {
            AddText("[color="+color+"]" + txt + "[/color]");
        }
    }
}

function showsize(size) {
    if (helpstat) {
        alert(hpshowsizehelppre+size+hpshowsizehelpmid+size+hpshowsizehelppost);
    } else if (basic) {
        AddText("[size=" + size + "][/size]");
    } else {
        txt = prompt(hpSize + size, hpText);
        if (txt != null) {
            AddText("[size=" + size + "]" + txt + "[/size]");
        }
    }
} 

function showfont(font) {
    if (helpstat) {
        alert("字体标记\r\n\r\n给文字设置字体.\r\n\r\n用法: [font="+font+"]改变文字字体为"+font+"[/font]");
    } else if (basic) {
        AddText("[font=" + font + "][/font]");
    } else {
        txt = prompt(hpFont + font, hpText);
        if (txt != null) {
            AddText("[font=" + font + "]" + txt + "[/font]");
        }
    }  
}

function bold() {
    if (helpstat) {
        alert("加粗标记\r\n\r\n使文本加粗.\r\n\r\n用法: [b]这是加粗的文字[/b]");
    } else if (basic) {
        AddTxt="[b][/b]";AddText(AddTxt);
    } else {
        txt = prompt("文字将被变粗.", hpText);
        if (txt != null) {
            AddText("[b]" + txt + "[/b]");
        }
    }
}
function italicize() {
    if (helpstat) {
        alert("斜体标记\r\n\r\n使文本字体变为斜体.\r\n\r\n用法: [i]这是斜体字[/i]");
    } else if (basic) {
        AddText("[i][/i]");
    } else {
        txt=prompt("文字将变斜体", hpText);
        if (txt!=null) {
            AddText("[i]" + txt + "[/i]");
        }
    }
}

function underline() {
    if (helpstat) {
        alert("下划线标记\r\n\r\n给文字加下划线.\r\n\r\n用法: [u]要加下划线的文字[/u]");
    } else if (basic) {
         AddText("[u][/u]");
    } else {
        txt=prompt("下划线文字.", hpText);
        if (txt!=null) {
            AddText("[u]" + txt + "[/u]");
        }
    }
}

function center() {
    if (helpstat) {
        alert("对齐标记\r\n\r\n使用这个标记, 可以使文本左对齐、居中、右对齐.\r\n\r\n用法: [align=center|left|right]要对齐的文本[/align]");
    } else if (basic) {
         AddTxt="[align=center|left|right][/align]";AddText(AddTxt);
    } else {
        txt2=prompt("对齐样式\r\n\r\n输入 'center' 表示居中, 'left' 表示左对齐, 'right' 表示右对齐.","center");
        while ((txt2!="") && (txt2!="center") && (txt2!="left") && (txt2!="right") && (txt2!=null)) {
            txt2=prompt("错误!\r\n\r\n类型只能输入 'center' 、 'left' 或者 'right'.","");
        }
        txt=prompt("要对齐的文本", hpText);
        if (txt!=null) {
            AddTxt="[align="+txt2+"]"+txt;AddText(AddTxt);AddTxt="[/align]";AddText(AddTxt);
        }
    }
}

function hyperlink() {
    if (helpstat) {
        alert("超级链接标记\r\n\r\n插入一个超级链接标记\r\n\r\n使用方法: [url]http://www.1313s.com[/url]\r\n\r\nUSE: [url=http://www.1313s.com]链接文字[/url]");
    } else if (basic) {
        AddText('[url][/url]');
    } else {
        txt2=prompt("链接文本显示.\r\n\r\n如果不想使用, 可以为空, 将只显示超级链接地址. ",""); 
        if (txt2!=null) {
            txt = prompt("超级链接.","http://");
            if (txt!=null) {
                if (txt2=="") {
                    AddText("[url]" + txt + "[/url]");
                } else {
                    AddText("[url=" + txt + "]" + txt2 + "[/url]");
                }
            }
        }
    }
}

function image() {
    if (helpstat) {
        alert("图片标记\r\n\r\n插入图片\r\n\r\n用法： [img]http:\/\/www.1313s.com\/baby.jpg[/img]");
    } else if (basic) {
        AddText("[img][/img]");
    } else {
        txt = prompt("图片的 URL","http://");
        if(txt != null) {
            AddText("[img]" + txt + "[/img]");
        }
    }
}

function quote() {
    if (helpstat) {
        alert("引用标记\r\n\r\n引用一些文字.\r\n\r\n用法: [quote]引用内容[/quote]");
    } else if (basic) {
        AddText("[quote][/quote]");
    } else {
        txt=prompt("被引用的文字", hpText);
        if(txt!=null) {
            AddText("[quote]" + txt + "[/quote]");
        }
    }
}

function flash() {
    if (helpstat){
        alert("Flash 动画\r\n\r\n插入 Flash 动画.\r\n\r\n用法: [flash]Flash 文件的地址[/flash]");
    } else if (basic) {
        AddText("[swf][/swf]");
    } else {
        txt=prompt("Flash 文件的地址","http://");
        if (txt!=null) {
            AddText("[flash]" + txt + "[/flash]");
        }
    }  
}

function music() {
    if (helpstat){
        alert("在线音/视频播放\r\n\r\n播放 URL 地址\r\n\r\n用法： [muisc]http:\/\/www.CGIer.com\/demo.wmv[/muisc]");
    } else if (basic) {
        AddText("[muisc][/muisc]");
    } else {
        txt=prompt("在线音/视频播放 (mms及http均可)", "http://");
        if(txt!=null) {
            AddText("[muisc]" + txt + "[/muisc]");
        }
    }
}