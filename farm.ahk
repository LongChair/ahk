

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
		; get the current first fleet position
		Pos := Context.FleetPositions(attack.fleets[1])
		
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
        
		target := PeekClosestTarget(Targets[collect.target], 0, 0)
		
		if (target =="")
		{
			Log(Format("no more targets '{1}' found.", collect.target))
			return 1
		}
		Else
		{
			if ((A_now - Context.killtimes[collect.source]) < (20 * 60))
			{
				Log(Format("Collecting {1} at ({2}, {3}) ...", collect.target, target.x, target.y))
				
				if (!collect(collect, target.x, target.y))
				{
					Log("ERROR : (collect) failed to complete collection. exiting", 2)
					return 0	
				}
				
				Log("Collection completed.")
			}
			else
			{
				Log(Format("Not Collecting '{1}', last attack time is too old!", collect.target))
			}				
		}

	}
	
	return 1
}