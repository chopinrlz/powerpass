console.log('debug: loading static.js');

function getRandomVersionNumber() {
	return ((Math.floor(Math.random() * Math.floor(100000000))).toFixed(0));
}

function addScriptAtHeader(name) {
	var script = document.createElement('script');
	script.src = name + '?v=' + getRandomVersionNumber();
	document.getElementsByTagName('head')[0].appendChild(script);
}