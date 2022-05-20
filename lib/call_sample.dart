import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_openvidu_demo/utils/signaling.dart';

class CallSampleWidget extends StatefulWidget {
  CallSampleWidget({Key key, @required this.server, this.sessionName, this.userName, this.secret, this.iceServer}) : super(key: key);

  final String server;
  final String sessionName;
  final String userName;
  final String secret;
  final String iceServer;

  @override
  _CallSampleWidgetState createState() => _CallSampleWidgetState();
}

class _CallSampleWidgetState extends State<CallSampleWidget> {

  final _localRenderer = new RTCVideoRenderer();
  final _remoteRenderer = new RTCVideoRenderer();

  Signaling _signaling;
  bool _isMute = false;

  @override
  void initState() {
    super.initState();

    initRenderers();
  }

  Future<void> initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    _connect();
  }

  void _hangUp() {
    if (_signaling != null) {
      Navigator.of(context).pop();
    }
  }

  void _switchCamera() {
    _signaling.switchCamera();
  }

  void _muteMic() {
    bool isAudioEnabled = _signaling.muteMic();
    print('_muteMic result : $isAudioEnabled');
    setState(() {
      _isMute = !isAudioEnabled;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: OrientationBuilder(builder: (context, orientation) {
        return new Container(
          child: new Stack(children: <Widget>[
            new Positioned(
              left: 0.0,
              right: 0.0,
              top: 0.0,
              bottom: 0.0,
              child: new Container(
                margin: new EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                child: new RTCVideoView(_remoteRenderer),
                decoration: new BoxDecoration(color: Colors.black54),
              )
            ),
            new Positioned(
              left: 20.0,
              top: 40.0,
              child: new Container(
                width: orientation == Orientation.portrait ? 90.0 : 120.0,
                height: orientation == Orientation.portrait ? 120.0 : 90.0,
                child: new RTCVideoView(_localRenderer),
                decoration: new BoxDecoration(color: Colors.black54),
              ),
            ),
          ]),
        );
      }),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: new SizedBox(
        width: 200.0,
        child: new Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            FloatingActionButton(
              child: const Icon(Icons.switch_camera),
              onPressed: _switchCamera,
              heroTag: "btn_switchCamera",
            ),
            FloatingActionButton(
              onPressed: _hangUp,
              heroTag: "btn_hangUp",
              tooltip: 'Hangup',
              child: new Icon(Icons.call_end),
              backgroundColor: Colors.pink,
            ),
            _isMute ?
            FloatingActionButton(
              child: const Icon(Icons.mic_off),
              onPressed: _muteMic,
              heroTag: "btn_muteMic",
            ) :
            FloatingActionButton(
              child: const Icon(Icons.mic_none),
              onPressed: _muteMic,
              heroTag: "btn_muteMic",
            )
          ]
        )
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _signaling?.close();
    _localRenderer?.dispose();
    _remoteRenderer?.dispose();
    print('◤◢◤◢◤◢◤◢◤◢◤ dispose() ALL ◤◢◤◢◤◢◤◢◤◢◤');
  }

  Future<void> _connect() async {
    
    if (_signaling == null) {

      //_Init Signaling
      _signaling = new Signaling(widget.server, widget.secret, widget.userName, widget.iceServer);

      //_Create session
      final String sessionId = await _signaling.createWebRtcSession(sessionId: widget.sessionName);
      print('◤◢◤◢◤◢◤◢◤◢◤ sessionId: $sessionId  ◤◢◤◢◤◢◤◢◤◢◤ ');

      //_Create_token
      final String token = await _signaling.createWebRtcToken(sessionId: sessionId);
      print('◤◢◤◢◤◢◤◢◤◢◤ token: $token  ◤◢◤◢◤◢◤◢◤◢◤ ');
    
      //_Connect_socket //ADDED AWAIT
      await _signaling.connect();

      _signaling.onStateChange = (SignalingState state) {
        print('_signaling.onStateChange: $state');
        switch (state) {
          case SignalingState.CallStateNew:
            break;
          case SignalingState.CallStateBye:
            break;
          case SignalingState.CallStateWaiting:
            _remoteRenderer.srcObject = null;
            setState(() {});
            print('empty remote src');
            break;
          default:
            break;
        }
      };

      _signaling.onLocalStream = ((stream) {
        print('onLocalStream: ${stream.id}');
        _localRenderer.srcObject = stream;
        setState(() {});
      });

      _signaling.onAddRemoteStream = ((stream) {
        print('onAddRemoteStream: ${stream.id}');
        _remoteRenderer.srcObject = stream;
        setState(() {});
      });

      _signaling.onRemoveRemoteStream = ((stream) {
        print('onRemoveRemoteStream');
        _remoteRenderer.srcObject = null;
      });
    }
    _signaling.onParticipantsRemove = ((remoteParticipant) {
      print('onParticipantsRemove :$remoteParticipant ');
    });
    _signaling.onParticipantsJoined = ((remoteParticipant) {
      print('onParticipantsJoined :$remoteParticipant ');
    });
    _signaling.onParticipantsStreamUpdate = ((remoteParticipant) {
      print('onParticipantsStreamUpdate :$remoteParticipant ');
    });
    _signaling.onMessageReceive = ((params) {
      print('onMessageReceive :$params ');
    });
    _signaling.onUserId = ((userId) {
      print('onUserId :$userId ');
    });
    _signaling.onSelfEvict = ((userId) {
      _remoteRenderer.srcObject = null;
      setState(() {});
      print('onSelfEvict :$userId ');
    });
  }
}
