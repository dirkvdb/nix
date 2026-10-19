{
  mqtt = {
    enabled = true;
    host = "mqtt.lan";
    port = 8883;
    tls_ca_certs = "/run/secrets/mqtt-ca.crt";
    tls_insecure = false;
    user = "{FRIGATE_MQTT_USER}";
    password = "{FRIGATE_MQTT_PASSWORD}";
  };
  tls.enabled = false;
  auth.enabled = true;
  database.path = "/config/frigate.db";
  ffmpeg.hwaccel_args = "preset-vaapi";
  detectors.ov = {
    type = "openvino";
    device = "GPU";
  };
  model = {
    model_type = "ssd";
    width = 300;
    height = 300;
    input_tensor = "nhwc";
    input_pixel_format = "bgr";
    path = "/openvino-model/ssdlite_mobilenet_v2.xml";
    labelmap_path = "/openvino-model/coco_91cl_bkgr.txt";
  };
  go2rtc.streams = {
    birdcam = [ "{FRIGATE_BIRDCAM_MAIN_URL}" ];
    birdcam_sub = [ "{FRIGATE_BIRDCAM_SUB_URL}" ];
    benchcam = [ "{FRIGATE_BENCHCAM_MAIN_URL}" ];
    benchcam_sub = [ "{FRIGATE_BENCHCAM_SUB_URL}" ];
  };
  cameras.birdcam = {
    enabled = true;
    ffmpeg.inputs = [
      {
        path = "{FRIGATE_BIRDCAM_MAIN_URL}";
        roles = [
          "audio"
          "record"
        ];
      }
      {
        path = "{FRIGATE_BIRDCAM_SUB_URL}";
        roles = [ "detect" ];
      }
    ];
    detect.enabled = false;
    live.streams = {
      main_stream = "birdcam";
      sub_stream = "birdcam_sub";
    };
    motion = {
      threshold = 50;
      contour_area = 20;
      improve_contrast = true;
      mask = "0.629,0.154,0.653,0.714,0.975,0.626,0.942,0.014";
    };
    notifications.enabled = true;
    zones.Nest = {
      coordinates = "0.145,0.305,0.259,0.982,0.561,0.868,0.431,0.163";
      loitering_time = 0;
      inertia = 3;
    };
    review.alerts.required_zones = [ "Nest" ];
  };
  cameras.benchcam = {
    enabled = true;
    detect = {
      enabled = true;
      fps = 5;
    };
    ffmpeg.inputs = [
      {
        path = "rtsp://127.0.0.1:8554/benchcam";
        input_args = "preset-rtsp-restream";
        roles = [ "record" ];
      }
      {
        path = "rtsp://127.0.0.1:8554/benchcam_sub";
        input_args = "preset-rtsp-restream";
        roles = [ "detect" ];
      }
    ];
    live.streams = {
      main_stream = "benchcam";
      sub_stream = "benchcam_sub";
    };
  };
  detect.enabled = true;
  record = {
    enabled = true;
    alerts.retain.days = 30;
    detections.retain.days = 30;
    continuous.days = 0;
    motion.days = 7;
  };
  version = "0.17-0";
  notifications = {
    enabled = true;
    email = "{FRIGATE_NOTIFICATION_EMAIL}";
  };
}
