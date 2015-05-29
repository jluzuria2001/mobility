#require previously install the following packeges
#sudo apt-get install python-pip
#sudo pip install requests
#sudo pip install paho-mqtt


#!/usr/bin/python

import requests
import sys
import json
import time

try:
    import paho.mqtt.client as mqtt
except ImportError:
    # This part is only required to run the example from within the examples
    # directory when the module itself is not installed.
    #
    # If you have the module installed, just use "import paho.mqtt.client"
    import os
    import inspect
    cmd_subfolder = os.path.realpath(os.path.abspath(os.path.join(os.path.split(inspect.getfile( inspect.currentframe() ))[0],"../src")))
    if cmd_subfolder not in sys.path:
        sys.path.insert(0, cmd_subfolder)
    import paho.mqtt.client as mqtt


MQTT_SERVER = "127.0.0.1"
MQTT_PORT = 1883
TOPIC_RESPONSE = "test-topic_mqtt"

#https://dweet.io/dweet/for/my-thing-name?hello=world&foo=bar

def on_connect(mqttc, obj, flags, rc):
    print("rc: "+str(rc))

def on_message(mqttc, obj, msg):
    headers = {'Content-type': 'application/json', 'Accept': 'text/plain'}

    value=timestamp()


    if msg.topic == TOPIC_RESPONSE:
        print "Message received with topic: %s, QoS: %s\n"%(msg.topic, str(msg.qos))

        #dweet with a thing name
#       print dweet_by_name(name="test_thing", data={"hello": "world"}) 
        newdata=json.loads(msg.payload)

        try:
#               string='https://dweet.io/dweet/for/'+TOPIC_RESPONSE+'?'+data
                url='http://dweet.io/dweet/for/'+TOPIC_RESPONSE

                r = requests.get(url, params=newdata)
                print r.status_code

        except requests.exceptions.ConnectionError, e:
                raise e

def on_publish(mqttc, obj, mid):
    print("mid: "+str(mid))

def on_subscribe(mqttc, obj, mid, granted_qos):
    print("Subscribed: "+str(mid)+" "+str(granted_qos))

def on_log(mqttc, obj, level, string):
    print(string)


def timestamp():
   now = time.time()
   localtime = time.localtime(now)
   milliseconds = '%03d' % int((now - int(now)) * 1000)
   return time.strftime('%Y%m%d%H%M%S', localtime) + milliseconds




# If you want to use a specific client id, use
# mqttc = mqtt.Client("client-id")
# but note that the client id must be unique on the broker. Leaving the client
# id parameter empty will generate a random id for you.
mqttc = mqtt.Client()
mqttc.on_message = on_message
mqttc.on_connect = on_connect
mqttc.on_publish = on_publish
mqttc.on_subscribe = on_subscribe
# Uncomment to enable debug messages
#mqttc.on_log = on_log

mqttc.connect(MQTT_SERVER,MQTT_PORT,60)
#mqttc.connect("m2m.eclipse.org", 1883, 60)

mqttc.subscribe(TOPIC_RESPONSE,1)
#mqttc.subscribe("$SYS/#", 0)

mqttc.loop_forever()
