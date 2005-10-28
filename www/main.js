/* $Id$ */

function report(o) {
	var s = ''
	for (var i in o)
		s += i + ' '
	alert(s)
}

function adj() {

}

var selparent = null

function selnode(dim, nid, sx, sy, ex, ey) {
	var e_img = getimg('img' + dim)

	if (e_img && document.createElement) {
		if (selparent && selparent.firstChild)
			selparent.removeChild(selparent.firstChild)
		var e_cell = e_img.parentNode
		var e_div = document.createElement('div')
		var e_pdiv = document.createElement('div')
		var s = 'position: relative;'
		e_pdiv.setAttribute('style', s)
/*
		if (s != e_pdiv.getAttribute('style'))
			return
*/
		s = 'border: 1px solid yellow; ' +
		   'position: absolute; z-index: 5; ' +
		   'left: ' + (sx - 1) + 'px; top: ' + (sy - 1) + 'px; ' +
		   'width: ' + (ex - sx + 1) + 'px; height: ' + (ey - sy + 1) + 'px;'
		e_div.setAttribute('style', s)
/*
		if (s != e_div.getAttribute('style'))
			return
*/
		e_pdiv.appendChild(e_div)
		e_cell.removeChild(e_img)
		e_cell.appendChild(e_pdiv)
		e_cell.appendChild(e_img)

		selparent = e_cell

		var pl = getobj('pl_node')
		if (pl) {
			pl.innerHTML = 'selected node ' + nid
		}
	}
}

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
	return (make_url(window.location.pathname, up))
}

function seljob(id) {
	var j = invjmap[id]
	var pl = getobj('pl_node')
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

function getimg(name) {
	if (document.images)
		return (document.images[name])
	return (null)
}

var jobs = []
var invjmap = []

function Job(id) {
	this.id = id
	jobs[jobs.length] = invjmap[id] = this
	return (this)
}

function preload(imgsrc) {
	if (document.images)
		new Image().src = imgsrc
}
