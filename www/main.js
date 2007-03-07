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

var nstates = [ 'Free', 'Down (CPA)', 'Disabled (PBS)', 'Used', 'Service' ]

function selnode() {
	if (document.cookie && document.cookie.match(/nodeinfo=(\d+)/)) {
		var nid = RegExp.$1
		var n = nodes[nid]
		if (n == null)
			return

		var pl = getobj('pl_node')
		pl.innerHTML = '<b>- Node Information -</b><br />' +
		    'NID: ' + n.id

		if (n.st)
			pl.innerHTML += '<br />State: ' + nstates[n.st]

		if (n.x && n.y && n.z)
			pl.innerHTML += '<br />Wired position: (' +
			    n.x + ',' + n.y + ',' + n.z + ')'

		if (n.r && n.cb && n.cg && n.m && n.n)
			pl.innerHTML += '<br />Hardware name: c' +
			    n.cb + '-' + n.r + 'c' + n.cg + 's' +
			    n.m + 's' + n.n

		if (Number(n.jobid))
			pl.innerHTML += '<br />Job ID: ' + n.jobid + ' (' +
			    '<a href="' + mkurl_job(n.jobid) +
			    '">View only this job</a>)'

		if (n.temp && Number(n.temp))
			pl.innerHTML += '<br />Temperature: ' + n.temp + '&deg;C'
		else
			pl.innerHTML += '<br />Temperature: N/A'
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
	var j = jobs[id]
	var pl = getobj('pl_job')
	if (j && pl) {
		pl.innerHTML = '<b>- Job Information -</b><br />' +
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

		if (Number(j.yodid) && yods[j.yodid]) {
			var y = yods[j.yodid]

			pl.innerHTML += 'Yod ID: ' + y.id + '<br />'

			if (y.cmd)
				pl.innerHTML += 'Yod command: ' + y.cmd + '<br />'
		}

		pl.innerHTML += 'Cores: ' +
		    (j.singlecore ? 'single' : 'dual') + '<br />'
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

function Job(id) {
	this.id = id
	jobs[id] = this
	return (this)
}

var nodes = []

function Node(id) {
	this.id = id
	nodes[id] = this
	return (this)
}

var yods = []

function Yod(id) {
	this.id = id
	yods[id] = this
	return (this)
}
