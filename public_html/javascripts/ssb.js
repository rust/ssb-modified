function switch_pane(pane_name) {
    var target_tab = $('tab_' + pane_name);
    var target_pane = $('pane_' + pane_name);

    all_tabs = document.getElementsByClassName('tab');
    $A(all_tabs).each(function(elem) {
            if(elem != target_tab) {
                elem.className = 'tab tab_close';
            } else {
                elem.className = 'tab tab_open';
            }
        });

    all_panes = document.getElementsByClassName('pane');
    $A(all_panes).each(function(elem) {
            if(elem != target_pane) {
                elem.className = 'pane pane_close';
            } else {
                elem.className = 'pane pane_open';
            }
        });

    var manager = new CookieManager();
    manager.setCookie('pane', pane_name);
}

function switch_pane_event(event) {
    switch_pane(event.target.id.replace("tab_", ""));
}

function get_active_panename() {
    // active pane
    active_tab = document.getElementsByClassName('tab_open')[0];
    return active_tab.id.replace('tab_', '');
}

function save_terminal_info(event) {
    Event.stop(event);
	save_all_cookies();
    window.location.reload();
}

function clear_terminal_info(event) {
    Event.stop(event);
	clear_all_cookies();
    window.location.reload();
}

function save_suggest_terminai_info(event) {
    var manager = new CookieManager();
	var val = SSB.ktai_db[$("term_search").value];
	if(val) {
		$('field_useragent').value = val['useragent'];
		save_all_cookies();
		window.location.reload();
	} else {
		$('term_search').value = '';
	}
	Event.stop(event);
}

function save_all_cookies() {
    var manager = new CookieManager();
    keys = ['homepage', 'mailaddr', 'useragent',
            'uid', 'hid', 'icc', 'exheader'];
    keys.each(function(key) {
            var val = $F('field_' + key);
            manager.setCookie(key, encodeURIComponent(val));
        });
	manager.setCookie('pane', manager.getCookie('pane'));
}

function clear_all_cookies() {
    var manager = new CookieManager();
    keys = ['homepage', 'mailaddr', 'useragent',
            'uid', 'hid', 'icc', 'exheader'];
    keys.each(function(key) {
            manager.clearCookie(key);
        });
	manager.clearCookie('pane');
}

function initialize() {
    // page focus
    var page = document.getElementById('page')
    if(page) {
        page.focus();
    }

    // tab click event (switch pane)
    var tabs = document.getElementsByClassName('tab');
    $A(tabs).each(function(tab){
            Event.observe(tab, 'click', switch_pane_event, false);
        });

    // save to cookie
    var manager = new CookieManager();
    var pane = manager.getCookie('pane');
    if(pane) {
        switch_pane(pane);
    } else {
        switch_pane('status');
    }

    // terminal setting form
    var term_form = $('term_form');
    Event.observe(term_form, 'submit', save_terminal_info, true);
    Event.observe(term_form, 'reset', clear_terminal_info, true);

    // ktai suggest
	Event.observe($('suggest_start'), 'click', function(event) {
			$('suggest_start').toggle();
			$('suggest_form').innerHTML = '機種名: <input type="text" id="term_search" autocomplete="off" /><input type="submit" value="OK" />';
			$('term_search').focus();
			Event.observe($('suggest_form'), 'submit', save_suggest_terminai_info, true);
			new Suggest.Local('term_search',
							  'term_select',
							  SSB.ktai_list,
							  {
								  highlight: true,
									  dispAllKey: true,
									  dispMax: 20
									  });
			Event.stop(event);
		}, true);
}

Event.observe(window, 'load', initialize);
