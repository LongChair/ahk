#include utils.ahk

farm(op)
{
    global Context
    
	; first got to favorite
	Log(Format("Going to favorite {1}...", op.favorite))
	if (!GoToFavorite(op.favorite))
	{
		Log(Format("ERROR : (favorite) failed to go to favorite {1}. exiting", op.favorite), 2)
		return 0
	}
	
	; scan the system
	Log(Format("Scanning system '{1}'...", op.system))
	Targets := Scan(op.system, op.scan)
	
	
	; proceed with attacks
	for i, attack in op.attacks
	{
	
		if (!IsActive(attack))
			goto Farm_Next_Attack
			
		; get the current first fleet position
		if (attack.fleets[1] != "all")
			Pos := Context.FleetPositions(attack.fleets[1])
		Else
		{
			Pos := {}
			Pos.x := 0
			Pos.y := 0
		}
		
		target := PeekClosestTarget(Targets[attack.target], Pos.x, Pos.y)
		
		if (target =="")
		{
			Log(Format("no more targets '{1}' found.", attack.target))
			Goto Farm_Next_Attack
		}
		Else
		{
			Log(Format("Processing attack {1} on '{2}', attacking target at ({3}, {4})", i, attack.target, target.x, target.y))
			
			ret := attack(attack, target.x, target.y)
			if (!ret)
			{
				Log("ERROR : (attack) failed to complete attack. exiting", 2)
				return 0	
			}
			
			if (ret == 1)
            {
				Log("Attack completed.")                
            }
			Else
			{
				; put back target in the list
				Targets[attack.target].push(target)
			}
		}
		
		SaveScan(Targets)
		
		Farm_Next_Attack:
	}
	
Farm_Collect:
	; proceed with collection
	for i, collect in op.collections
	{
        
		if (!IsActive(collect))
			goto Farm_Collect_Next_Collect
		
		
		startmin := GetObjectProperty(collect, "startmin", 0)
		stopmin  := GetObjectProperty(collect, "stopmin", 20)
		
		
		if (collect.source != "")
		{
			ElapsedTime := A_now 
			ElapsedTime -= Context.killtimes[collect.source], seconds
		}
		Else
			ElapsedTime := (startmin + stopmin) * 60 / 2
		
		
		if ((ElapsedTime >= 60 * startmin) AND (ElapsedTime <= 60 * stopmin)) OR 0
		{
			
			Farm_Collect_Next_Target:	
			
			if IsObject(Context.Killpos[collect.source])
			{
				posx := Context.Killpos[collect.source].x
				posy := Context.Killpos[collect.source].y
			}
			Else
			{
				posx := 0
				posy := 0
			}
			
			radius := GetObjectProperty(collect, "radius", 10000)
			target := PeekClosestTarget(Targets[collect.target], posx, posy, radius)
			;target := PeekFurthestTarget(Targets[collect.target], 0, 0)
			
			if (target =="")
			{
				Log(Format("no more targets '{1}' found.", collect.target))
				goto Farm_Collect_Next_Collect
			}
			Else
			{
			
				Log(Format("Collecting {1} at ({2}, {3}) ...", collect.target, target.x, target.y))
				
				ret := collect(collect, target.x, target.y)
				
				switch ret
				{
					case 0:					
						Log("ERROR : (collect) failed to complete collection. exiting", 2)
						return 0	
						
					case 1:
						Log("Collection completed.")
						
					case 2:
						return 1
						
					case 3:
						Log("Failed to collect but going to next target.")
						Goto Farm_Collect_Next_Target
				}
							
			}
			
			
		}
		else
		{
			Log(Format("Not Collecting '{1}', time window not matching : {4:.1f} -> range {2} - {3}", collect.target, startmin, stopmin , ElapsedTime / 60 ))
		}
		
		Farm_Collect_Next_Collect:
	}
	
	return 1
}