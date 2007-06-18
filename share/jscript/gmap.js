function iwl_validate_degrees (value, max) {
    var sign = '+';
    var int = 0;
    var fract = 0;
    
    var reg = /^(?:[^-+]*([-+]))?[^0-9]*([0-9]*)[^.,]*(?:[.,][^0-9]*([0-9]+))?/;
    ar = reg.exec (value);
    if (ar[1])
	sign = ar[1];
    if (ar[2])
	int = ar[2];
    if (ar[3])
	fract = ar[3];

    if (int > 180) {
	int = 180;
	fract = 0;
    }

    return '' + sign + int + '.' + fract;
}

function iwl_validate_latitude (value) {
    return iwl_validate_degrees (value, 90);
}

function iwl_validate_longitude (value) {
    return iwl_validate_degrees (value, 180);
}

function iwl_gmap_format (map, format) {
    var result = '';

    var i;
    for (i = 0; i < format.length; ++i) {
        var letter = format.charAt (i);
	if (i < format.length - 1 && letter == '%') {
	    var next_letter = format.charAt (i + 1);
	    
	    switch (next_letter) {
	        case 'c':
		    result += map.getCenter().toString();
		    ++i;
		    break;
		case 'w':
		    var val = map.getCenter().lat();
		    var sign = val >= 0 ? '+' : '';
		    result += sign + val;
		    ++i;
		    break;
		case 'l':
		    var val = map.getCenter().lng();
		    var sign = val >= 0 ? '+' : '';
		    result += sign + val;
		    ++i;
		    break;
		case 'z':
		    var val = map.getZoom();
		    result += val;
		    ++i;
		    break;
		case '%':
		    result += '%';
		    break;
	        default:
		    result += letter + next_letter;
	    }
	} else {
	    result += letter;
	}
    }

    return result;
}

function iwl_gmap_update_input (map, id, format) {
    var input = document.getElementById (id);
    if (!input) return;

    var str = iwl_gmap_format (map, format);

    // FIXME: textarea, select, ...
    input.value = str;
}

function iwl_gmap_update_container (map, id, format) {
    var container = document.getElementById (id);
    if (!container) return;

    var str = iwl_gmap_format (map, format);

    container.innerHTML = str;
}

