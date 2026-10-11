import urllib.request
import urllib.error
import uuid

url = 'https://recipie-generator-qwj4.onrender.com/api/v1/recipes/analyze-image'
img_path = r'C:/Users/ymuke/.gemini/antigravity/brain/020f6b92-cc9d-4d4a-8a61-af6fd460ea8a/.user_uploaded/media_1791696274097_397252a7.jpg'

with open(img_path, 'rb') as f:
    img_data = f.read()

boundary = '----WebKitFormBoundary' + uuid.uuid4().hex
headers = {'Content-Type': f'multipart/form-data; boundary={boundary}'}

body = bytearray()
body.extend(f'--{boundary}\r\n'.encode('utf-8'))
body.extend(b'Content-Disposition: form-data; name="file"; filename="dish.jpg"\r\n')
body.extend(b'Content-Type: image/jpeg\r\n\r\n')
body.extend(img_data)
body.extend(f'\r\n--{boundary}--\r\n'.encode('utf-8'))

req = urllib.request.Request(url, data=bytes(body), headers=headers)
try:
    print('Sending analyze-image request...')
    res = urllib.request.urlopen(req, timeout=90)
    print('Status:', res.status)
    print('Response:', res.read().decode('utf-8'))
except urllib.error.HTTPError as e:
    print('HTTPError:', e.code, e.read().decode('utf-8'))
except Exception as e:
    print('Error:', e)
