import json, os, urllib.request, urllib.error
from http.server import BaseHTTPRequestHandler, HTTPServer
SECRET=os.environ.get("VULCAN_PLATFORM_SECRET","")
GATEWAY=os.environ.get("GATEWAY_URL","https://admin.byvulcan.com/api/ai-gateway")
PRODUCT=os.environ.get("PRODUCT","vulcan-office")
DEFAULT_TASK=os.environ.get("DEFAULT_TASK_TYPE","chat")
MODELS=[m for m in os.environ.get("MODELS","vulcan-office,vulcan-fast,vulcan-full").split(",") if m]
class H(BaseHTTPRequestHandler):
  def _cors(self):
    self.send_header("Access-Control-Allow-Origin","*")
  def _j(self,c,o):
    b=json.dumps(o).encode(); self.send_response(c)
    self.send_header("Content-Type","application/json"); self.send_header("Content-Length",str(len(b))); self._cors()
    self.end_headers(); self.wfile.write(b)
  def do_OPTIONS(self):
    self.send_response(204); self._cors()
    self.send_header("Access-Control-Allow-Headers","*"); self.send_header("Access-Control-Allow-Methods","GET,POST,OPTIONS")
    self.end_headers()
  def do_GET(self):
    p=self.path.split("?")[0].rstrip("/")
    if p=="/health": return self._j(200,{"ok":True})
    if p in ("/v1/models","/models"):
      return self._j(200,{"object":"list","data":[{"id":m,"object":"model","owned_by":"vulcan"} for m in MODELS]})
    return self._j(404,{"error":"nf"})
  def _gateway(self,body):
    tt=body.get("task_type") or self.headers.get("x-task-type") or DEFAULT_TASK
    payload=json.dumps({"task_type":tt,"messages":body.get("messages",[]),
      "user_id":body.get("user") or body.get("user_id") or "00000000-0000-0000-0000-000000000000",
      "product":PRODUCT,"max_tokens":body.get("max_tokens",1024)}).encode()
    req=urllib.request.Request(GATEWAY,data=payload,method="POST")
    req.add_header("Content-Type","application/json"); req.add_header("x-vulcan-secret",SECRET); req.add_header("x-product-id",PRODUCT)
    return json.loads(urllib.request.urlopen(req,timeout=60).read())
  def do_POST(self):
    try:
      n=int(self.headers.get("Content-Length",0)); body=json.loads(self.rfile.read(n) or b"{}")
    except Exception: return self._j(400,{"error":"bad_json"})
    try:
      g=self._gateway(body)
    except urllib.error.HTTPError as e: return self._j(e.code,{"error":"gateway","detail":e.read()[:200].decode("utf-8","ignore")})
    except Exception as e: return self._j(502,{"error":"unreachable","detail":str(e)})
    content=g.get("content",""); model=g.get("model",""); rid=g.get("request_id","")
    u=g.get("usage") or {}
    usage={"prompt_tokens":u.get("input_tokens",0),"completion_tokens":u.get("output_tokens",0),"total_tokens":u.get("input_tokens",0)+u.get("output_tokens",0)}
    if body.get("stream"):
      self.send_response(200)
      self.send_header("Content-Type","text/event-stream"); self.send_header("Cache-Control","no-cache")
      self.send_header("Connection","close"); self._cors(); self.end_headers()
      def ev(o): self.wfile.write(("data: "+json.dumps(o)+"\n\n").encode()); self.wfile.flush()
      ev({"id":rid,"object":"chat.completion.chunk","model":model,"choices":[{"index":0,"delta":{"role":"assistant","content":content},"finish_reason":None}]})
      ev({"id":rid,"object":"chat.completion.chunk","model":model,"choices":[{"index":0,"delta":{},"finish_reason":"stop"}]})
      self.wfile.write(b"data: [DONE]\n\n"); self.wfile.flush()
      return
    self._j(200,{"id":rid,"object":"chat.completion","model":model,
      "choices":[{"index":0,"message":{"role":"assistant","content":content},"finish_reason":g.get("stop_reason","stop")}],"usage":usage})
  def log_message(self,*a): pass
print("aiproxy :8800",flush=True); HTTPServer(("0.0.0.0",8800),H).serve_forever()
