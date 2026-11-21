const mirrorReceiverHtml = r'''
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no">
<title>Sanketa Mirror</title>
<style>
:root{--bg:#000;--overlay:rgba(0,0,0,.55);--ctrl:rgba(255,255,255,.15);--ctrl-active:rgba(255,255,255,.35);--text:#fff;--dot-ok:#22c55e;--dot-warn:#eab308;--dot-err:#ef4444}
*{margin:0;padding:0;box-sizing:border-box}
html,body{width:100%;height:100%;overflow:hidden;background:var(--bg)}
#player{position:absolute;inset:0;width:100%;height:100%;background:var(--bg)}
#status{position:fixed;top:12px;right:12px;width:10px;height:10px;border-radius:50%;z-index:20;transition:background .3s}
#status.ok{background:var(--dot-ok)}
#status.warn{background:var(--dot-warn)}
#status.err{background:var(--dot-err)}
#overlay{position:fixed;inset:0;display:flex;align-items:center;justify-content:center;background:var(--overlay);color:var(--text);font:600 1.2rem/1.4 system-ui,sans-serif;z-index:30;opacity:0;pointer-events:none;transition:opacity .25s}
#overlay.show{opacity:1;pointer-events:auto}
#controls{position:fixed;bottom:0;left:0;right:0;display:flex;justify-content:center;gap:8px;padding:14px 16px;background:var(--overlay);z-index:10;transform:translateY(100%);transition:transform .25s}
#controls.show{transform:translateY(0)}
#controls button{background:var(--ctrl);color:var(--text);border:none;border-radius:6px;padding:8px 18px;font:500 .85rem system-ui,sans-serif;cursor:pointer;transition:background .15s}
#controls button.active{background:var(--ctrl-active)}
#controls button:hover{background:var(--ctrl-active)}
#error{position:fixed;inset:0;display:flex;align-items:center;justify-content:center;background:var(--bg);color:var(--text);font:500 1rem system-ui,sans-serif;text-align:center;padding:24px;z-index:40;display:none}
</style>
</head>
<body>
<video id="player" playsinline autoplay muted></video>
<div id="status" class="warn"></div>
<div id="overlay">Connecting&hellip;</div>
<div id="controls">
  <button data-fit="contain" class="active">Fit</button>
  <button data-fit="cover">Fill</button>
  <button data-fit="fill">Stretch</button>
</div>
<div id="error"></div>

<script src="https://cdn.jsdelivr.net/npm/jmuxer@2.0.5/dist/jmuxer.min.js"></script>
<script>
(function(){
  var video = document.getElementById('player');
  var status = document.getElementById('status');
  var overlay = document.getElementById('overlay');
  var controls = document.getElementById('controls');
  var errorEl = document.getElementById('error');
  var ws = null;
  var jmuxer = null;
  var reconnectTimer = null;
  var controlsTimer = null;
  var audioStarted = false;

  if(typeof JMuxer === 'undefined'){
    errorEl.style.display = 'flex';
    errorEl.textContent = 'Failed to load video decoder. Check your network connection.';
    return;
  }

  function getWsUrl(){
    var params = new URLSearchParams(location.search);
    var wsParam = params.get('ws');
    if(wsParam && wsParam.indexOf('ws') === 0) return wsParam;
    var host = params.get('host') || location.hostname;
    var port = wsParam || params.get('port') || '0';
    return 'ws://' + host + ':' + port;
  }

  function setFit(mode){
    video.style.objectFit = mode;
    var btns = controls.querySelectorAll('button');
    for(var i=0;i<btns.length;i++){
      btns[i].classList.toggle('active', btns[i].getAttribute('data-fit') === mode);
    }
    try{ localStorage.setItem('sanketa_fit', mode); }catch(e){}
  }

  function loadFit(){
    try{
      var saved = localStorage.getItem('sanketa_fit');
      if(saved && (saved==='contain'||saved==='cover'||saved==='fill')) return saved;
    }catch(e){}
    return 'contain';
  }

  setFit(loadFit());

  controls.addEventListener('click', function(e){
    var btn = e.target.closest('button[data-fit]');
    if(btn) setFit(btn.getAttribute('data-fit'));
  });

  var showControls = false;
  video.addEventListener('click', function(){
    showControls = !showControls;
    controls.classList.toggle('show', showControls);
    clearTimeout(controlsTimer);
    if(showControls){
      controlsTimer = setTimeout(function(){ showControls=false; controls.classList.remove('show'); }, 5000);
    }
  });

  function tryUnmute(){
    if(!audioStarted){
      audioStarted = true;
      video.muted = false;
      video.volume = 1.0;
    }
  }

  document.addEventListener('click', tryUnmute, {once:true});
  document.addEventListener('touchstart', tryUnmute, {once:true});

  function initMuxer(){
    if(jmuxer){ try{jmuxer.destroy();}catch(e){} }
    jmuxer = new JMuxer({
      node: 'player',
      mode: 'both',
      flushingTime: 0,
      fps: 30,
      debug: false,
      onReady: function(){ video.play().catch(function(){}); }
    });
  }

  function connect(){
    clearTimeout(reconnectTimer);
    overlay.textContent = 'Connecting…';
    overlay.classList.add('show');
    status.className = 'warn';

    var url = getWsUrl();
    try{ ws = new WebSocket(url); }catch(e){
      scheduleReconnect();
      return;
    }
    ws.binaryType = 'arraybuffer';

    ws.onopen = function(){
      status.className = 'ok';
      overlay.classList.remove('show');
      initMuxer();
    };

    ws.onmessage = function(evt){
      if(!(evt.data instanceof ArrayBuffer) || evt.data.byteLength < 5) return;
      var view = new Uint8Array(evt.data);
      var type = view[0];
      var frameData = new Uint8Array(evt.data, 5);

      if(type === 0x09) return;

      if(!jmuxer) return;

      if(type === 0x01 || type === 0x02){
        jmuxer.feed({video: frameData, duration: 33});
      } else if(type === 0x03){
        jmuxer.feed({audio: frameData, duration: 23});
        tryUnmute();
      }
    };

    ws.onclose = function(){
      status.className = 'err';
      scheduleReconnect();
    };

    ws.onerror = function(){
      try{ ws.close(); }catch(e){}
    };
  }

  function scheduleReconnect(){
    overlay.textContent = 'Reconnecting…';
    overlay.classList.add('show');
    status.className = 'err';
    reconnectTimer = setTimeout(connect, 2000);
  }

  connect();
})();
</script>
</body>
</html>
''';
