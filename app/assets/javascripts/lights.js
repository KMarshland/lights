function initializeLightWebsocket(){
    var scheme   = window.location.protocol == 'https:' ? "wss://" : "ws://";
    var uri      = scheme + window.document.location.host + "/";
    var ws       = new WebSocket(uri);

    $('#on').on('change', function(){
        var that = $(this);
        var on = that.is(':checked');
        ws.send(JSON.stringify({lights: on}));
        $.ajax({
            url: '/lights',
            type: 'POST',
            data: {
                on: on
            },
            error: function(){
                that.prop("checked", !that.prop("checked"));
            }
        });
    });

    ws.onmessage = function(message) {
        console.log('WS Message: ' + message.data, message);
    };
}