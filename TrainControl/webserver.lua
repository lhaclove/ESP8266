--[[

cfg = {}
cfg.ssid = "TrainControl"
cfg.pwd = "TrainRulez"
wifi.ap.config(cfg)
wifi.setmode(wifi.SOFTAP)
--]]

wifi.setmode(wifi.STATION)
wifi.sta.config("KoviNet","")
wifi.sta.connect();

-- outputs: D1, D2
-- inputs: D5, D6

frequency = 1000

pwm.setup(1, frequency, 0)
pwm.setup(2, frequency, 0)

pwm.start(1)
pwm.start(2)

irpin1 = 5
irstop1 = false
irpin2 = 6
irstop2 = false

html1 =
[[
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="icon" href="data:;base64,=">
    <title>TrainControl</title>
    <script type="text/javascript">
    function send(url) {
        var xmlhttp = new XMLHttpRequest();
        xmlhttp.open("post", url, true);
        xmlhttp.send();
    }
    </script>
  </head>
  <body>
    <h1>TrainControl</h1>
]]

html2 =
[[
    <form>
       speed (+/- 1023): <input type="text" name="speed" id="speed" value="0" size="5">
        <input type="button" value="set" onclick="send(document.getElementById('speed').value);">
        <br />
        <input type="button" value="stop" onclick="send(0);">
    </form>
  </body>
</html>]]

response = "HTTP/1.1 200 OK\r\nContent-Length: 0\r\n\r\n"

function split(text, pattern)
  array = {}
  local index = 0
  for i in string.gmatch(text, pattern) do
    array[index] = i
    index = index + 1
  end
  return array
end

function getFirstLine(text)
  local start, stop = string.find(text, "\n")
  --print(start)
  local firstLine = string.sub(text, 0, start)
  --print(firstLine)
  return firstLine
end

function getFileName(payload)
  local firstLine = getFirstLine(payload)
  --print(firstLine)
  local fileName = split(firstLine, "%S+")[1]
  --print(fileName)
  return fileName
end

function processPost(payload)
  -- collectgarbage()
  -- print(node.heap())
  if string.sub(payload, 0, 4) ~= "POST" then return false end
  local fileName = getFileName(payload)
  print("filename")
  print(fileName)
  --if fileName ~= "/" then return end
  local command = string.sub(fileName, 2)
  print("Command:")
  print(command)
  local speed = tonumber(command)
  if not (speed == nil) then setSpeed(speed) end
  return true
end

function setSpeed(speed)
  if speed > 1023 then
    speed = 1023
  elseif speed < -1023 then
    speed = -1023
  end

  if speed==0 then
    pwm.setduty(1, 0)
    pwm.setduty(2, 0)
  elseif speed > 0 and (not irstop1) then
    pwm.setduty(2, 0)
    pwm.setduty(1, speed)
  elseif speed < 0 and (not irstop2) then
    pwm.setduty(1, 0)
    pwm.setduty(2, speed * -1)
  end
end

print("Initilaizing webserver...")

if not (srv == nil) then srv:close() end
srv=net.createServer(net.TCP)
srv:listen(80, function(conn)
 conn:on("receive", function(conn,payload)
  --print("payload:")
  --print(payload)
  --print("payload end")
  if not processPost(payload) then
    conn:send(html1)
    conn:send(html2)
  else
    conn:send(response)
  end
 end)
 conn:on("sent", function(conn)
  conn:close()
 end)
end)

print("Listening...")
print("")

--[[

function updateIr1()
    irstop1 = gpio.read(irpin1) == 0
    if irstop1 then
      print("irstop1 was true")
      setSpeed(0)
    end
end

function updateIr2()
    irstop2 = gpio.read(irpin2) == 0
    if irstop2 then
      print("irstop2 was true")
      setSpeed(0)
    end
end


gpio.mode(irpin1, gpio.INT)
gpio.trig(irpin1, "both", updateIr1)

gpio.mode(irpin2, gpio.INT)
gpio.trig(irpin2, "both", updateIr2)

updateIr1()
updateIr2()
--]]
