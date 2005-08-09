/* $Id$ */

function adj() {

}

function selnode(dim, nid, sx, sy, ex, ey) {
	var e_img = getimg('img' + dim)

/*
var s = ''
for (var i in img)
 s += i + ' ';
alert(s)
alert(img.parentNode.firstChild.name)
*/

	if (e_img && document.createElement) {
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
	}
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
