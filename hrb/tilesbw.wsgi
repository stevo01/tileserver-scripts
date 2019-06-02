#!/usr/bin/python
#
# fetch tile and write to stdout in grayscale
#

URL_BASE='/tilesbw'
URL_BASE_TARGET='http://localhost'

import urllib, cStringIO
from PIL import Image
import sys
import re

# "main"
def application(env, start_response):
  # our URI must be in the form http://<our-server>/<URL_BASE>/<z>/<x>/<y>.png
  regex=URL_BASE + '/(.+)/([0-9]+)/([0-9]+)/([0-9]+)\.png'
  uri = env.get('REQUEST_URI', '')
  res=re.findall(regex,uri)
  
  if len(res) != 1:
    output='ERROR, invalid Tile URL: %s\n' % uri
    content_type = "text/plain"
  else:
    content_type = "image/png"
    # build URL
    URL=URL_BASE_TARGET+'/'+res[0][1]+'/'+res[0][2]+'/'+res[0][3]+'.png'
    sys.stderr.write(URL+'\n')
    file = cStringIO.StringIO(urllib.urlopen(URL).read())
    img = Image.open(file).convert('L')
    buf = cStringIO.StringIO()
    img.save(buf, "PNG")
    output = buf.getvalue()
  
  response_headers = [('Content-type', content_type),
                      ('Content-Length', str(len(output)))]

  status = '200 OK'
  start_response(status, response_headers)
  return output

  