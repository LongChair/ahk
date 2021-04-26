
#include libs\JSON.ahk


json_str = 
(
{
    "start": "080000",
    "end": "100000"
}
)

t := JSON.Load(json_str)

a := IsActive(t)

t.start := "170000"
t.end := "180000"

a := IsActive(t)

t.start := "190000"
t.end := "200000"

a := IsActive(t)

IsActive(time)
{
    DT1 := format("{1}{2}{3}{4}", A_YYYY, A_MM, A_DD, time.start)
    DT2 := format("{1}{2}{3}{4}", A_YYYY, A_MM, A_DD, time.end)
    
    if ((A_now >= DT1) AND (A_Now <= DT2))
        return 1
    else
        return 0
}