
#Include  %A_ScriptDir% 
#include libs\JSON.ahk
#include utils.ahk

Sleep, 5000

Loop, 5
{
    MouseClickDrag L, 800, 800, 800, 200, 2 
    Sleep, 500
}

Loop, 5
{
    MouseClickDrag L, 800, 200, 800, 800, 2 
    Sleep, 500
}
i := 10
b := [7,8]
json_str = 
(
{
    "loc": {
        "x": 0,
        "y": %i%
    },
    "approach" : true,
    "fleets" : [1,2,3]
}
)

p := JSON.Load(json_str)

blah := p.Clone()
blah.fleets := [4,5,6]



SaveObjectToJSON(blah, "blach.json")


global Result := ""

FileRead json_str, Config.json

config := JSON.Load(json_str)
if (ProcessOperations(config.operations))
    A := Result

ProcessOperations(ops)
{
    For i,op in ops
    {
        if (op.name=="repeat")
        {
            Loop, % op.count
            {
                if (!ProcessOperations(op.operations))
                    return 0
            }
        }
        else
          Loop, % op.count
          {
              if (!DoOperation(op))
                    return 0
          }
    }
    
    return 1
}

DoOperation(op)
{
  Result := Result . "`r`n" . op.name
  return 1
}
