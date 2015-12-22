1. Download and setup flex sdk (need java runtime)

2. Add library path in /path/to/flexsdk/frameworks/flex-config.xml
<library-path>
    ...
    <path-element>path/to/src/leelib/util/flvEncoder/alchemy</path-element>

3. run in console:
```
mxmlc ./leelibExamples/flvEncoder/webcam/WebcamRealTimeApp.as
```

flashvars:
 - uploadUrl     - path/to/upload.php
 - clientId      - ������������� �������
 - token         - ����. �����
 - framerate     - ������� ������ � �������
 - recordTimeout - ����������������� ������ ����� �� �����.���������
 - useGuiHelper  - ������ ���������� ����������� ����� js (����� flash)
 - autoStopOnly  - ��� ����������� ��������� ����� ������ "����" �� ��������� recordTimeout
 - &debug        - debug mode
