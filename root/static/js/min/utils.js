$(function(){$(document.forms).each(function(theform){$(theform).submit(function(){$('input:submit').attr({disabled:'disabled'});$('input:reset').attr({disabled:'disabled'});});$(theform).keypress(function(evt){var x=evt.keyCode;var q=evt.ctrlKey;if(q&&(x==13||x==10)){theform.submit();}});});var _zeroPad=function(num){var s='0'+num;return s.substring(s.length-2)
};$(".date").each(function(i){var s=$(this).text();var f=this.id;if(!f){f='yyyy-mm-dd hh:ii:ss';}
var d=new Date(1997,1,1,1,1,1);var iY=f.indexOf('yyyy');if(iY>-1){d.setFullYear(Number(s.substr(iY,4)));}
var iM=f.indexOf('mm');if(iM>-1){d.setMonth(Number(s.substr(iM,2))-1);}
d.setDate(Number(s.substr(f.indexOf('dd'),2)));d.setHours(Number(s.substr(f.indexOf('hh'),2)));d.setMinutes(Number(s.substr(f.indexOf('ii'),2)));d.setSeconds(Number(s.substr(f.indexOf('ss'),2)));var timezoneOffset=-(new Date().getTimezoneOffset());d.setMinutes(d.getMinutes()+timezoneOffset);if(isNaN(d.getFullYear())){return false;}
var t=f
.split('yyyy').join(d.getFullYear())
.split('mm').join(_zeroPad(d.getMonth()+1))
.split('dd').join(_zeroPad(d.getDate()))
.split('hh').join(_zeroPad(d.getHours()))
.split('ii').join(_zeroPad(d.getMinutes()))
.split('ss').join(_zeroPad(d.getSeconds()));$(this).text(t);});});