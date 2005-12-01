/* $Id$ */

function report(o) {
	var s = ''
	for (var i in o)
		s += i + ' '
	alert(s)
}

function escapeHTML(s) {
	return (s.replace(/[^a-zA-Z0-9 !@#$%^*()\[\]\/\\,.;:|_=+-]/, '&#' +
	    RegExp.$1.charCodeAt(0) + ';'))
}

function selnode() {
	if (document.cookie) {
		var pl = getobj('pl_node')
		pl.innerHTML = '<br />' + '<b>Node Information</b><br>' +
		    escapeHTML(document.cookie)
	}
}

window.onload = selnode

function mkurl_hl(grp) {
	var up = url_getparams(window.location)
	up['hl'] = grp
	up['smode'] = 'jobs'
	delete up['job']
	return (make_url(window.location.pathname, up))
}

function mkurl_job(id) {
	var up = url_getparams(window.location)
	up['job'] = id
	up['smode'] = 'jobs'
	delete up['hl']
	delete up['click']
	return (make_url(window.location.pathname, up))
}

function seljob(id) {
	var j = invjmap[id]
	var pl = getobj('pl_job')
	if (j && pl) {
		pl.innerHTML = '<b>Job Information</b><br />' +
		    'ID: ' + j.id + '<br />' +
		    (j.name  ? 'Name: '   + j.name  + '<br />' : '') +
		    (j.owner ? 'Owner: '  + j.owner + '<br />' : '') +
		    (j.queue ? 'Queue: '  + j.queue + '<br />' : '') +
		    (j.ncpus ? 'NCPUS: '  + j.ncpus + '<br />' : '') +
		    (j.mem   ? 'Memory: ' + j.mem   + 'KB<br />' : '')
		if (j.dur_used && j.dur_want) {
			var du_hr = parseInt(j.dur_used / 60)
			var du_min = j.dur_used % 60
			if (du_min < 10)
				du_min = '0' + du_min

			var dw_hr = parseInt(j.dur_want / 60)
			var dw_min = j.dur_want % 60
			if (dw_min < 10)
				dw_min = '0' + dw_min

			var prog = parseInt(100 * j.dur_used / j.dur_want)

			pl.innerHTML += 'Time: ' +
			    du_hr + ':' + du_min + '/' +
			    dw_hr + ':' + dw_min +
			    ' (' + prog + '%)' + '<br />'
		}
		pl.innerHTML += '<br />'
	}
}

function url_getparams(s) {
	var search = ''
	if (String(s).match(/\?(.*)/))
		search = RegExp.$1
	var parts = search.split(/&(amp;)?/)
	var params = defparams
	for (var i in parts) {
		var cnps = parts[i].split(/=/, 2)
		if (cnps.length == 2)
			params[cnps[0]] = cnps[1]
	}
	return (params)
}

function url_getbase(s) {
	return (s.replace(/\?.*/, ''))
}

function make_url(s, up) {
	s += '?'
	for (var i in up)
		s += i + '=' + up[i] + '&' /* XXX escape */
	return (s)
}

function getobj(id) {
	if (document.getElementById)
		return (document.getElementById(id))
	else if (document.all)
		return (document.all(id))
	return (null)
}

var jobs = []
var invjmap = []

function Job(id) {
	this.id = id
	jobs[jobs.length] = invjmap[id] = this
	return (this)
}
