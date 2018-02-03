
param ($SettingsFile, 
       $OutputDirectory,
       $ItemCount,
       $StartDate,
       $Years,
       $Customers,
       $Transports,
       $Demands,
       $Activities,
       $WithKey,
       $Slices,
	   $SupCanSupply,
	   $CommonItems,
	   $IntlSuppliers,
	   $DomSuppliers,
	   $ItemRatio);
       $ScriptStartTime=Get-Date;
       $ActivityHash=@{};
       $ResourceHash=@{};
	   $LocationHash=@{};
	   $ResActHash=@{};
	   $FindResKeyHash=@{};
	   $FindActKeyHash=@{};
function generateDataMain
{ 
  loadparameters;
  write-host $ItemRatio;
  write-host $DomSuppliers;
  write-host $IntlSuppliers;
  $LocationsArray=@();
  
  for($locind=0;$locind -lt $Stores;$locind++)
  {
  $LocationsArray+=($locind);
  }
  for($locind=0;$locind -lt ($LDC1/2);$locind++)
  {
   $LocationsArray+=(6000+$locind);
  }

  for($locind=0;$locind -lt ($LDC1/2);$locind++)
  {
   $LocationsArray+=(6500+$locind);
  }
  for($locind=0;$locind -lt ($LDC2/2);$locind++)
  {
   $LocationsArray+=(5000+$locind);
  }
  for($locind=0;$locind -lt ($LDC2/2);$locind++)
  {
   $LocationsArray+=(5500+$locind);
  }
   for($locind=0;$locind -lt ($IntlSuppliers);$locind++)
  {
   $LocationsArray+=(7000+$locind);
  }
for($locind=0;$locind -lt ($DomSuppliers);$locind++)
  {
   $LocationsArray+=(8000+$locind); 
  }
  
  generateItems $ItemCount;
  generateTime $StartDate $Years;
  generateStorages  $Storages $LocationsArray $DCs $Stores $LDC1 $LDC2;
  generateProduct $ItemCount;
  generateResources  $LocationsArray $DomSuppliers $IntlSuppliers $Stores $LDC1 $LDC2;
  generateCustomers $Customers;
  generateTransports $Transports;
  generateDemands $Demands;
  generateActivities $Activities $LocationsArray $DomSuppliers $IntlSuppliers $Stores $LDC1 $LDC2;
  generateLocations $LocationsArray;
  $ItemRatio=[double]$ItemRatio;
  $FirstItemIntl=0
  $LastItemIntl=$ItemRatio*$ItemCount;
  $FirstItemDom=$ItemRatio*$ItemCount;
  $LastItemDom=$ItemCount;
 
  Write-Host "Writing Material Production Graph...";    
  $FileNamePrefix = 'Fact.MaterialProductionGraph'
  $sliceId = 0;
  $Jobs = @();
  
  $StartItemIntl=$FirstItemIntl;
  $EndItemIntl=$LastItemIntl;
  $StartItemDom=$FirstItemDom;
  $EndItemDom=$LastItemDom;
  1..$Slices | ForEach-Object { $sliceId = 0; } {
    $jobName = "FactMaterialProductionGraph-Slice-$($sliceId)";
    $job = Start-Job -Name $jobName -ScriptBlock $generateMaterialProductionGraph -ArgumentList $OutputDirectory,$ItemCount,$Transports,$FileNamePrefix,$sliceId,$LocationsArray,$Stores,$ActivityHash,$LocationHash,$SupCanSupply,$LDC1,$LDC2,$IntlSuppliers,$DomSuppliers,$Slices,$StartItemIntl,$EndItemIntl,$StartItemDom,$EndItemDom;
	$sliceId++;
    $Jobs += $job.ID;
  }
  Wait-Job -Id $Jobs;
  
  Write-Host "Writing Material Consumption Graph...";    
  $FileNamePrefix = 'Fact.MaterialConsumptionGraph'
  $sliceId = 0;
  $Jobs = @();
  $StartItemIntl=$FirstItemIntl;
  $EndItemIntl=$LastItemIntl;
  $StartItemDom=$FirstItemDom;
  $EndItemDom=$LastItemDom;
  1..$Slices | ForEach-Object { $sliceId = 0; } {
    $jobName = "FactMaterialConsumptionGraph-Slice-$($sliceId)";
    $job = Start-Job -Name $jobName -ScriptBlock $generateMaterialConsumptionGraph -ArgumentList $OutputDirectory,$ItemCount,$Transports,$FileNamePrefix,$sliceId,$LocationsArray,$Stores,$ActivityHash,$LocationHash,$SupCanSupply,$LDC1,$LDC2,$IntlSuppliers,$DomSuppliers,$Slices,$StartItemIntl,$EndItemIntl,$StartItemDom,$EndItemDom;
   
	$sliceId++;
    $Jobs += $job.ID;
  }
  Wait-Job -Id $Jobs;
  write-host $ResActHash.count;
  Write-Host "Writing Capacity Consumption Graph...";    
  $FileNamePrefix = 'Fact.CapacityConsumptionGraph'
  $sliceId = 0;
  $Jobs = @();
  $StartItemIntl=$FirstItemIntl;
  $EndItemIntl=$LastItemIntl;
  $StartItemDom=$FirstItemDom;
  $EndItemDom=$LastItemDom;
  1..$Slices | ForEach-Object { $sliceId = 0; } {
    $jobName = "CapacityConsumptionGraph-Slice-$($sliceId)";
    $job = Start-Job -Name $jobName -ScriptBlock $generateCapacityConsumptionGraph -ArgumentList $OutputDirectory,$ItemCount,$Transports,$FileNamePrefix,$sliceId,$LocationsArray,$Stores,$LDC1,$LDC2,$ActivityHash,$ResourceHash,$LocationHash,$SupCanSupply,$Slices,$ResActHash,$IntlSuppliers,$DomSuppliers,$StartItemIntl,$StartItemDom,$EndItemIntl,$EndItemDom,$FindActKeyHash,$FindResKeyHash;
  
	$sliceId++;
    $Jobs += $job.ID;
  }
  Wait-Job -Id $Jobs;
  <#
   Write-Host "Writing Demand Quantity..."; 

  $FileNamePrefix = 'Fact.DemandQuantity'
  $sliceId = 0;
  $Jobs = @();
  
  $EndItem=[math]::floor($ItemCount/$Slices);
  1..$Slices | ForEach-Object { $sliceId = 0; } {
    $jobName = "DemandQuantity-Slice-$($sliceId)";
    $job = Start-Job -Name $jobName -ScriptBlock $generateDemand -ArgumentList $OutputDirectory,$StartDate,$Years,$Demands,$Customers,$ItemCount,$FileNamePrefix,$sliceId,$StartItemIntl,$EndItemIntl,$StartItemDom,$EndItemDom,$LocationsArray,$DomSuppliers,$IntlSuppliers,$Stores,$LDC1,$LDC2;
    $sliceId++;
   
    $Jobs += $job.ID;
  }
  Wait-Job -Id $Jobs;
  <#
    Write-Host "Writing Activity Parameters..."; 
   
  $FileNamePrefix = 'Fact.ActivityParameters'
  $sliceId = 0;
  $Jobs = @();
  $StartItemIntl=$FirstItemIntl;
  $EndItemIntl=$LastItemIntl;
  $StartItemDom=$FirstItemDom;
  $EndItemDom=$LastItemDom;
  1..$Slices | ForEach-Object { $sliceId = 0; } {
    $jobName = "FactActivityParameters-Slice-$($sliceId)";
    $job = Start-Job -Name $jobName -ScriptBlock $generateActivityParameters -ArgumentList $OutputDirectory,$Transports,$ItemCount,$FileNamePrefix,$sliceId,$WithKey,$LocationsArray,$Stores,$ActivityHash,$SupCanSupply,$LDC1,$LDC2,$IntlSuppliers,$DomSuppliers,$Slices,$CommonItems,$StartItemIntl,$StartItemDom,$EndItemIntl,$EndItemDom;
    
	$sliceId++;
    $Jobs += $job.ID;
  }
  Wait-Job -Id $Jobs;
  
  
  Write-Host "Writing CapacityAvailability..."; 
  $FileNamePrefix = 'Fact.CapacityAvailability'
  $sliceId = 0;
  $Jobs = @();
  
  $EndRes=[math]::floor($ResourceHash.Count/$Slices);
  1..$Slices | ForEach-Object { $sliceId = 0; } {
    $jobName = "CapacityAvailability-Slice-$($sliceId)";
	write-host $StartRes $EndRes;
    $job = Start-Job -Name $jobName -ScriptBlock $generateCapacityAvailability -ArgumentList $OutputDirectory,$StartDate,$Years,$Version,$Resources,$FileNamePrefix,$sliceId,$LocationsArray,$IntlSuppliers,$DomSuppliers,$Stores,$ResourceHash,$LDC1,$LDC2,$LocationHash,$ResActHash,$FindActKeyHash;
    $sliceId++;
    
    $Jobs += $job.ID;
  }
  Wait-Job -Id $Jobs;
  #>
<#
  Write-Host "Writing MaterialProductionGraphPlannedWIP..."; 
  $FileNamePrefix = 'Fact.MaterialProductionGraphPlannedWIP'
  $sliceId = 0;
  $Jobs = @();
  $StartItemIntl=$FirstItemIntl;
  $EndItemIntl=$LastItemIntl;
  $StartItemDom=$FirstItemDom;
  $EndItemDom=$LastItemDom;
  1..$Slices | ForEach-Object { $sliceId = 0; } {
    $jobName = "MaterialProductionGraphPlannedWIP-Slice-$($sliceId)";
    $job = Start-Job -Name $jobName -ScriptBlock $generateMaterialProductionGraphPlannedWIP -ArgumentList $OutputDirectory,$ItemCount,$Transports,$StartDate,$FileNamePrefix,$sliceId,$LocationsArray,$Stores,$ActivityHash,$LocationHash,$SupCanSupply,$LDC1,$LDC2,$IntlSuppliers,$DomSuppliers,$Slices,$StartItemIntl,$EndItemIntl,$StartItemDom,$EndItemDom;
    
	$sliceId++;
    $Jobs += $job.ID;
  }
  Wait-Job -Id $Jobs;
  
  
  Write-Host "Writing Inventory..."; 
  $FileNamePrefix = 'Fact.Inventory'
  $sliceId = 0;
  $Jobs = @();
  $StartItemIntl=$FirstItemIntl;
  $EndItemIntl=$LastItemIntl;
  $StartItemDom=$FirstItemDom;
  $EndItemDom=$LastItemDom;
  1..$Slices | ForEach-Object { $sliceId = 0; } {
    $jobName = "Inventory-Slice-$($sliceId)";
    $job = Start-Job -Name $jobName -ScriptBlock $generateInventory -ArgumentList $OutputDirectory,$StartDate,$Years,$ItemCount,$Version,$FileNamePrefix,$sliceId,$StartItemIntl,$EndItemIntl,$StartItemDom,$EndItemDom,$LocationsArray,$DomSuppliers,$IntlSuppliers,$Stores,$LDC1,$LDC2;
    $sliceId++;
    $Jobs += $job.ID;
  }
  Wait-Job -Id $Jobs;

     Write-Host "Writing Storage Graph..."; 
  $FileNamePrefix = 'Fact.StorageGraph';
  $sliceId = 0;
  $Jobs = @();
  
$StartItemIntl=$FirstItemIntl;
  $EndItemIntl=$LastItemIntl;
  $StartItemDom=$FirstItemDom;
  $EndItemDom=$LastItemDom;
  1..$Slices | ForEach-Object { $sliceId = 0; } {
    $jobName = "StorageGraph-Slice-$($sliceId)";
    $job = Start-Job -Name $jobName -ScriptBlock $generateStorageGraph -ArgumentList $OutputDirectory,$Locations,$ItemCount,$Version,$FileNamePrefix,$sliceId,$StartItemIntl,$EndItemIntl,$StartItemDom,$EndItemDom,$LocationsArray,$DomSuppliers,$IntlSuppliers,$Stores,$StartDate,$Years,$LDC1,$LDC2;
    $sliceId++;
    $StartItem+=$ItemWidth;
    if($sliceId -eq ($Slices-1)){
	    $EndItem+=[math]::floor($ItemCount/$Slices)+$ItemRem;
	}else{
    $EndItem+=[math]::floor($ItemCount/$Slices);
	}
	
    $Jobs += $job.ID;
  }
  Wait-Job -Id $Jobs;
  
  Write-Host "Writing Storage Availability..."; 
  $FileNamePrefix = 'Fact.StorageAvailability';
  $sliceId = 0;
  $Jobs = @();
  $StartItemIntl=$FirstItemIntl;
  $EndItemIntl=$LastItemIntl;
  $StartItemDom=$FirstItemDom;
  $EndItemDom=$LastItemDom;
  1..$Slices | ForEach-Object { $sliceId = 0; } {
    $jobName = "StorageAvailability-Slice-$($sliceId)";
    $job = Start-Job -Name $jobName -ScriptBlock $generateStorageAvailability -ArgumentList $OutputDirectory,$StartDate,$Years,$Locations,$ItemCount,$Version,$FileNamePrefix,$sliceId,$WithKey,$StartItemIntl,$EndItemIntl,$StartItemDom,$EndItemDom,$LocationsArray,$DomSuppliers,$IntlSuppliers,$Stores,$LDC1,$LDC2;
    $sliceId++;
   
	
    $Jobs += $job.ID;
  }
  Wait-Job -Id $Jobs;
  
    Write-Host "Writing Material Node Parameters..."; 
  $FileNamePrefix = 'Fact.MaterialNodeParameters'
  $sliceId = 0;
  $Jobs = @();
$StartItemIntl=$FirstItemIntl;
  $EndItemIntl=$LastItemIntl;
  $StartItemDom=$FirstItemDom;
  $EndItemDom=$LastItemDom;
  1..1 | ForEach-Object { $sliceId = 0; } {
    $jobName = "MaterialNodeParameters-Slice-$($sliceId)";
    $job = Start-Job -Name $jobName -ScriptBlock $generateMaterialNodeParameters -ArgumentList $OutputDirectory,$StartDate,$Years,$ItemCount,$Version,$FileNamePrefix,$sliceId,$SupCanSupply,$LocationsArray,$LDC1,$LDC2,$Stores,$LocationHash,$CommonItems,$DomSuppliers,$IntlSuppliers,$StartItemIntl,$StartItemDom,$EndItemIntl,$EndItemDom;
    $sliceId++;
   
    $Jobs += $job.ID;
  }
  Wait-Job -Id $Jobs;
  
    Write-Host "Writing Material Node Time Parameters..."; 
  $FileNamePrefix = 'Fact.MaterialNodeTimeParameters'
  $sliceId = 0;
  $Jobs = @();
  $StartItemIntl=$FirstItemIntl;
  $EndItemIntl=$LastItemIntl;
  $StartItemDom=$FirstItemDom;
  $EndItemDom=$LastItemDom;
  1..$Slices | ForEach-Object { $sliceId = 0; } {
    $jobName = "MaterialNodeTimeParameters-Slice-$($sliceId)";
    $job = Start-Job -Name $jobName -ScriptBlock $generateMaterialNodeTimeParameters -ArgumentList $OutputDirectory,$StartDate,$Years,$ItemCount,$Version,$FileNamePrefix,$sliceId,$StartItemIntl,$EndItemIntl,$StartItemDom,$EndItemDom,$LocationsArray,$DomSuppliers,$IntlSuppliers,$Stores,$LDC1,$LDC2;
    $sliceId++;
    $StartItem+=$ItemWidth;
    if($sliceId -eq ($Slices-1)){
	    $EndItem+=[math]::floor($ItemCount/$Slices)+$ItemRem;
	}else{
    $EndItem+=[math]::floor($ItemCount/$Slices);
	}
    $Jobs += $job.ID;
  }
  Wait-Job -Id $Jobs;
  
  #-------------------------------------------------------------------------------------------------------
  #>
   <#
  Write-Host "Writing CapacityGraphPlannedWIP..."; 
  $FileNamePrefix = 'Fact.CapacityGraphPlannedWIP'
  $sliceId = 0;
  $Jobs = @();
  $LocWidth=[math]::floor($Locations/$Slices);
  $StartLoc=0;
  $EndLoc=[math]::floor($Locations/$Slices);
  1..$Slices | ForEach-Object { $sliceId = 0; } {
    $jobName = "CapacityGraphPlannedWIP-Slice-$($sliceId)";
    $job = Start-Job -Name $jobName -ScriptBlock $generateCapacityGraphPlannedWIP -ArgumentList $OutputDirectory,$StartDate,$Years,$Locations,$Activities,$ItemCount,$Version,$Transports,$Resources,$FileNamePrefix,$sliceId,$WithKey,$StartLoc,$EndLoc;
    $sliceId++;
    $StartLoc+=$LocWidth;
    $EndLoc+=$LocWidth;
    $Jobs += $job.ID;
  }
  Wait-Job -Id $Jobs;
  #>
  
  <# Write-Host "Writing Material Node Time Parameters..."; 
  $FileNamePrefix = 'Fact.MaterialNodeTimeParameters'
  $sliceId = 0;
  $Jobs = @();
  $LocWidth=[math]::floor($Locations/$Slices);
  $StartLoc=0;
  $EndLoc=[math]::floor($Locations/$Slices);
  1..$Slices | ForEach-Object { $sliceId = 0; } {
    $jobName = "MaterialNodeParameters-Slice-$($sliceId)";
    $job = Start-Job -Name $jobName -ScriptBlock $generateMaterialTimeNodeParameters -ArgumentList $OutputDirectory,$StartDate,$Years,$Locations,$ItemCount,$Version,$FileNamePrefix,$sliceId,$WithKey,$StartLoc,$EndLoc;
    $sliceId++;
    $StartLoc+=$LocWidth;
    $EndLoc+=$LocWidth;
    $Jobs += $job.ID;
  }
  Wait-Job -Id $Jobs;
  #>
  
  <#
  Write-Host "Writing Material Node Consumption Holiday..."; 
  $FileNamePrefix = 'Fact.MaterialNodeConsumptionHoliday';
  $sliceId = 0;
  $Jobs = @();
  $LocWidth=[math]::floor($Locations/$Slices);
  $StartLoc=0;
  $EndLoc=[math]::floor($Locations/$Slices);
  1..$Slices | ForEach-Object { $sliceId = 0; } {
    $jobName = "MaterialNodeParameters-Slice-$($sliceId)";
    $job = Start-Job -Name $jobName -ScriptBlock $generateMaterialNodeConsumptionHoliday -ArgumentList $OutputDirectory,$StartDate,$Years,$Activities,$Locations,$ItemCount,$Version,$Transports,$FileNamePrefix,$sliceId,$WithKey,$StartLoc,$EndLoc;
    $sliceId++;
    $StartLoc+=$LocWidth;
    $EndLoc+=$LocWidth;
    $Jobs += $job.ID;
  }
  Wait-Job -Id $Jobs;
  Write-Host "Writing Material Node Production Holiday..."; 
  $FileNamePrefix = 'Fact.MaterialNodeProductionHoliday';
  $sliceId = 0;
  $Jobs = @();
  $LocWidth=[math]::floor($Locations/$Slices);
  $StartLoc=0;
  $EndLoc=[math]::floor($Locations/$Slices);
  1..$Slices | ForEach-Object { $sliceId = 0; } {
    $jobName = "MaterialNodeParameters-Slice-$($sliceId)";
    $job = Start-Job -Name $jobName -ScriptBlock $generateMaterialNodeProductionHoliday -ArgumentList $OutputDirectory,$StartDate,$Years,$Activities,$Locations,$ItemCount,$Version,$Transports,$FileNamePrefix,$sliceId,$WithKey,$StartLoc,$EndLoc;
    $sliceId++;
    $StartLoc+=$LocWidth;
    $EndLoc+=$LocWidth;
    $Jobs += $job.ID;
  }
  Wait-Job -Id $Jobs; 
  #>
  #.....
  

  <#Write-Host "Writing Time Varying Capacity Consumption..."; 
  $FileNamePrefix = 'Fact.TimeVaryingCapacityConsumption';
  $sliceId = 0;
  $Jobs = @();
  $LocWidth=[math]::floor($Locations/$Slices);
  $StartLoc=0;
  $EndLoc=[math]::floor($Locations/$Slices);
  1..$Slices | ForEach-Object { $sliceId = 0; } {
    $jobName = "StorageGraph-Slice-$($sliceId)";
    $job = Start-Job -Name $jobName -ScriptBlock $generateTimeVaryingCapacityConsumption -ArgumentList $OutputDirectory,$StartDate,$Years,$Storages,$Locations,$Activities,$ItemCount,$Version,$Transports,$Resources,$FileNamePrefix,$sliceId,$WithKey,$StartLoc,$EndLoc;
    $sliceId++;
    $StartLoc+=$LocWidth;
    $EndLoc+=$LocWidth;
    $Jobs += $job.ID;
  }
  Wait-Job -Id $Jobs;
  Write-Host "Writing Time Varying Material Consumption..."; 
  $FileNamePrefix = 'Fact.TimeVaryingMaterialConsumption';
  $sliceId = 0;
  $Jobs = @();
  $LocWidth=[math]::floor($Locations/$Slices);
  $StartLoc=0;
  $EndLoc=[math]::floor($Locations/$Slices);
  1..$Slices | ForEach-Object { $sliceId = 0; } {
    $jobName = "StorageGraph-Slice-$($sliceId)";
    $job = Start-Job -Name $jobName -ScriptBlock $generateTimeVaryingMaterialConsumption -ArgumentList $OutputDirectory,$StartDate,$Years,$Storages,$Locations,$Activities,$ItemCount,$Version,$Transports,$Resources,$FileNamePrefix,$sliceId,$WithKey,$StartLoc,$EndLoc;
    $sliceId++;
    $StartLoc+=$LocWidth;
    $EndLoc+=$LocWidth;
    $Jobs += $job.ID;
  }
  Wait-Job -Id $Jobs;
  Write-Host "Writing Time Varying Material Production..."; 
  $FileNamePrefix = 'Fact.TimeVaryingMaterialProduction';
  $sliceId = 0;
  $Jobs = @();
  $LocWidth=[math]::floor($Locations/$Slices);
  $StartLoc=0;
  $EndLoc=[math]::floor($Locations/$Slices);
  1..$Slices | ForEach-Object { $sliceId = 0; } {
    $jobName = "StorageGraph-Slice-$($sliceId)";
    $job = Start-Job -Name $jobName -ScriptBlock $generateTimeVaryingMaterialProduction -ArgumentList $OutputDirectory,$StartDate,$Years,$Storages,$Locations,$Activities,$ItemCount,$Version,$Transports,$Resources,$FileNamePrefix,$sliceId,$WithKey,$StartLoc,$EndLoc;
    $sliceId++;
    $StartLoc+=$LocWidth;
    $EndLoc+=$LocWidth;
    $Jobs += $job.ID;
  }
  Wait-Job -Id $Jobs; 
  #> #>
  $ScriptEndTime=Get-Date;
  Write-Host "Total Script Run Time is :"
  $ScriptEndTime-$ScriptStartTime;
}
$generateTimeVaryingMaterialProduction={
	param($OutputDirectory,$StartDate,$Years,$Storages,$Locations,$Activities,$ItemCount,$Version,$Transports,$Resources,$FileNamePrefix,$sliceId,$WithKey,$StartLoc,$EndLoc);
	$MPFile=[System.IO.StreamWriter] ("$OutputDirectory\$FileNamePrefix-$($sliceId).csv");
	[DateTime]$StartDate=get-date $StartDate;
	[DateTime]$EndDate=$StartDate.AddYears($Years);
    if(!($WithKey -eq 0))
    {
    $MPFile.writeline("Time.[TimeKey],Location.[LocationKey],Activity.[ActivityKey],Item.[ItemKey],Version.[VersionKey],Transport.[TransportKey],Product.[ProductKey],Time Varying Material Production");
      while($StartDate -lt $EndDate){
       for($LocInd=$StartLoc;$LocInd -lt $EndLoc;$LocInd++)
       {
          for($ItemInd=0;$ItemInd -lt $ItemCount;$ItemInd++)
          {
               for($ActInd=0;$ActInd -lt $Activities;$ActInd++)
               {
                  
                  for($TransInd=0;$TransInd -lt $Transports;$TransInd++)
                  {
                     $TVMP=get-random -minimum 100 -maximum 1000;
                     $WeekKey=get-date $StartDate -Format "yyyy-MM-dd";
                     $MPFile.writeline($WeekKey+","+$LocInd.ToString()+","+$ActInd+","+$ItemInd+",0,"+$TransInd+","+$ItemInd+","+$TVMP);
                   }
                   
               }
          }
        }
        $StartDate=$StartDate.AddDays(7);
        }
    }
    else
    {
      $MPFile.writeline("Time.[Time],Location.[Location],Activity.[Activity],Item.[Item],Version.[Version],Transport.[Transport],Product.[Product],Time Varying Material Production");
      while($StartDate -lt $EndDate){
       for($LocInd=$StartLoc;$LocInd -lt $EndLoc;$LocInd++)
       {
          for($ItemInd=0;$ItemInd -lt $ItemCount;$ItemInd++)
          {
               for($ActInd=0;$ActInd -lt $Activities;$ActInd++)
               {
                  
                  for($TransInd=0;$TransInd -lt $Transports;$TransInd++)
                  {
                     $TVMP=get-random -minimum 100 -maximum 1000;
                     $WeekKey=get-date $StartDate -Format "yyyy-MM-dd";
                     $MPFile.writeline($WeekKey+","+$LocInd.ToString()+","+$ActInd+",CurrentWorkingView,"+$ResInd+","+$TransInd+","+$ItemInd+","+$TVMP);
                   }
                   
               }
          }
        }
        $StartDate=$StartDate.AddDays(7);
        }
        }
$MPFile.close();
$Proc=Get-Job;
	Stop-Job $Proc.InstanceId;
}
$generateTimeVaryingMaterialConsumption={
	param($OutputDirectory,$StartDate,$Years,$Storages,$Locations,$Activities,$ItemCount,$Version,$Transports,$Resources,$FileNamePrefix,$sliceId,$WithKey,$StartLoc,$EndLoc);
    $MPFile=[System.IO.StreamWriter] ("$OutputDirectory\$FileNamePrefix-$($sliceId).csv");
	[DateTime]$StartDate=get-date $StartDate;
	[DateTime]$EndDate=$StartDate.AddYears($Years);
    if(!($WithKey -eq 0))
    {
    $MPFile.writeline("Time.[TimeKey],Location.[LocationKey],Activity.[ActivityKey],Item.[ItemKey],Version.[VersionKey],Transport.[TransportKey],Product.[ProductKey],Time Varying Material Consumption");
      while($StartDate -lt $EndDate){
       for($LocInd=$StartLoc;$LocInd -lt $EndLoc;$LocInd++)
       {
          for($ItemInd=0;$ItemInd -lt $ItemCount;$ItemInd++)
          {
               for($ActInd=0;$ActInd -lt $Activities;$ActInd++)
               {
                  
                  for($TransInd=0;$TransInd -lt $Transports;$TransInd++)
                  {
                     $TVMC=get-random -minimum 100 -maximum 1000;
                     $WeekKey=get-date $StartDate -Format "yyyy-MM-dd";
                     $MPFile.writeline($WeekKey+","+$LocInd.ToString()+","+$ActInd+","+$ItemInd+",0,"+$TransInd+","+$ItemInd+","+$TVMC);
                   }
                   
               }
          }
        }
        $StartDate=$StartDate.AddDays(7);
        }
    }
    else
    {
      $MPFile.writeline("Time.[Time],Location.[Location],Activity.[Activity],Item.[Item],Version.[Version],Transport.[Transport],Product.[Product],Time Varying Material Consumption");
      while($StartDate -lt $EndDate){
       for($LocInd=$StartLoc;$LocInd -lt $EndLoc;$LocInd++)
       {
          for($ItemInd=0;$ItemInd -lt $ItemCount;$ItemInd++)
          {
               for($ActInd=0;$ActInd -lt $Activities;$ActInd++)
               {
                  
                  for($TransInd=0;$TransInd -lt $Transports;$TransInd++)
                  {
                     $TVMC=get-random -minimum 100 -maximum 1000;
                     $WeekKey=get-date $StartDate -Format "yyyy-MM-dd";
                     $MPFile.writeline($WeekKey+","+$LocInd.ToString()+","+$ActInd+",CurrentWorkingView,"+$ResInd+","+$TransInd+","+$ItemInd+","+$TVMC);
                   }
                   
               }
          }
        }
        $StartDate=$StartDate.AddDays(7);
        }
        }
$MPFile.close();
$Proc=Get-Job;
	Stop-Job $Proc.InstanceId;
}
$generateTimeVaryingCapacityConsumption={
param($OutputDirectory,$StartDate,$Years,$Storages,$Locations,$Activities,$ItemCount,$Version,$Transports,$Resources,$FileNamePrefix,$sliceId,$WithKey,$StartLoc,$EndLoc);
$MPFile=[System.IO.StreamWriter] ("$OutputDirectory\$FileNamePrefix-$($sliceId).csv");
	[DateTime]$StartDate=get-date $StartDate;
	[DateTime]$EndDate=$StartDate.AddYears($Years);
    if(!($WithKey -eq 0))
    {
    $MPFile.writeline("Time.[FiscalWeekKey],Location.[LocationKey],Activity.[ActivityKey],Version.[VersionKey],Resource.[ResourceKey],Transport.[TransportKey],Product.[ProductKey],Time Varying Capacity Consumption");
      while($StartDate -lt $EndDate){
       for($LocInd=$StartLoc;$LocInd -lt $EndLoc;$LocInd++)
       {
          for($ItemInd=0;$ItemInd -lt $ItemCount;$ItemInd++)
          {
               for($ActInd=0;$ActInd -lt $Activities;$ActInd++)
               {
                  for($ResInd=0;$ResInd -lt $Resources;$ResInd++){
                  for($TransInd=0;$TransInd -lt $Transports;$TransInd++)
                  {
                     $TVCC=get-random -minimum 100 -maximum 1000;
                     $WeekKey=get-date $StartDate -Format "yyyy-MM-dd";
                     $MPFile.writeline($WeekKey+","+$LocInd.ToString()+","+$ActInd+",0,"+$ResInd+","+$TransInd+","+$ItemInd+","+$TVCC);
                   }
                   }
               }
          }
        }
        $StartDate=$StartDate.AddDays(7);
        }
    }
    else
    {
      $MPFile.writeline("Time.[Time],Location.[Location],Activity.[Activity],Version.[Version],Resource.[Resource],Transport.[Transport],Product.[Product],Time Varying Capacity Consumption");
      while($StartDate -lt $EndDate){
       for($LocInd=$StartLoc;$LocInd -lt $EndLoc;$LocInd++)
       {
          for($ItemInd=0;$ItemInd -lt $ItemCount;$ItemInd++)
          {
               for($ActInd=0;$ActInd -lt $Activities;$ActInd++)
               {
                  for($ResInd=0;$ResInd -lt $Resources;$ResInd++){
                  for($TransInd=0;$TransInd -lt $Transports;$TransInd++)
                  {
                     $TVCC=get-random -minimum 100 -maximum 1000;
                     $WeekKey=get-date $StartDate -Format "yyyy-MM-dd";
                     $MPFile.writeline($WeekKey+","+$LocInd.ToString()+","+$ActInd+",CurrentWorkingView,"+$ResInd+","+$TransInd+","+$ItemInd+","+$TVCC);
                   }
                   }
               }
          }
        }
        $StartDate=$StartDate.AddDays(7);
        }
        }
$MPFile.close();
$Proc=Get-Job;
	Stop-Job $Proc.InstanceId;
}
$generateStorageAvailability={
	param($OutputDirectory,$StartDate,$Years,$Locations,$ItemCount,$Version,$FileNamePrefix,$sliceId,$WithKey,$StartItemIntl,$EndItemIntl,$StartItemDom,$EndItemDom,$LocationsArray,$DomSuppliers,$IntlSuppliers,$Stores,$LDC1,$LDC2); 
	$MPFile=[System.IO.StreamWriter] ("$OutputDirectory\$FileNamePrefix-$($sliceId).csv");
	[DateTime]$StartDate=get-date $StartDate;
	[DateTime]$EndDate=$StartDate.AddYears($Years);
	$ModVal=$ItemCount/4;
   $StorageAvail=40000;
    
    $MPFile.writeline("Storage.[StorageKey],Time.[FiscalWeekKey],Version.[VersionKey],Product.[ProductKey],Band_1 Storage,Band_2 Storage,Storage Availability");
       $weekcnt=1;
	   while($StartDate -lt $EndDate){
       
                   for($StoreInd=0;$StoreInd -lt $LDC1;$StoreInd++){
                     for($ItemInd=$StartItemIntl;$ItemInd -lt $EndItemIntl;$ItemInd++){
                     $Storage="DC-"+$LocationsArray[$Stores+$StoreInd];
                     $WeekKey=get-date $StartDate -Format "yyyy-MM-dd";
                     $MPFile.writeline(($Stores+$StoreInd).ToString()+","+$WeekKey+",0,"+[math]::floor($ItemInd/$ModVal)+",,,"+$StorageAvail);
					 }
                   }
				    for($StoreInd=0;$StoreInd -lt $LDC2;$StoreInd++){
                     for($ItemInd=$StartItemIntl;$ItemInd -lt $EndItemIntl;$ItemInd++){
                     $Storage="DC-"+$LocationsArray[$Stores+$LDC1+$StoreInd];
                     $WeekKey=get-date $StartDate -Format "yyyy-MM-dd";
                     $MPFile.writeline(($Stores+$LDC1+$StoreInd).ToString()+","+$WeekKey+",0,"+$ItemInd+",,,"+$StorageAvail);
					 }
                   }
               
          
        $weekcnt++;
		if($weekcnt -gt 4)
        {
		  $StorageAvail=30000;
         }		
        $StartDate=$StartDate.AddDays(7);
        }
     
        

  $MPFile.close();
  $Proc=Get-Job;
	Stop-Job $Proc.InstanceId;
}
$generateStorageGraph={
	param($OutputDirectory,$Locations,$ItemCount,$Version,$FileNamePrefix,$sliceId,$StartItemIntl,$EndItemIntl,$StartItemDom,$EndItemDom,$LocationsArray,$DomSuppliers,$IntlSuppliers,$Stores,$StartDate,$Years,$LDC1,$LDC2);
	$MPFile=[System.IO.StreamWriter] ("$OutputDirectory\$FileNamePrefix-$($sliceId).csv");
	$ModVal=$ItemCount/4;
    
      $MPFile.writeline("Storage.[StorageKey],Location.[LocationKey],Item.[ItemKey],Version.[VersionKey],Product.[ProductKey],Storage Graph Association,Storage Qty Per");
      
       for($ItemInd=$StartItemIntl;$ItemInd -lt $EndItemDom;$ItemInd++)
          {
               
            for($StoreInd=0;$StoreInd -lt $Stores;$StoreInd++){
                     $B1Storage=get-random -minimum 100 -maximum 10000;
                     $B2Storage=get-random -minimum 100 -maximum 10000;
                     $StorageAvail=get-random -minimum 100 -maximum 10000;
                     $WeekKey=get-date $StartDate -Format "yyyy-MM-dd";
                     $Storage="Store-"+$LocationsArray[$StoreInd];
                     $MPFile.writeline($StoreInd.ToString()+","+$StoreInd+","+$ItemInd+",0,"+[math]::floor($ItemInd/$ModVal)+",1,1");
                   }
		   }
				   for($ItemInd=$StartItemIntl;$ItemInd -lt $EndItemIntl;$ItemInd++){
                   for($StoreInd=0;$StoreInd -lt $LDC1;$StoreInd++){
                     $B1Storage=get-random -minimum 100 -maximum 10000;
                     $B2Storage=get-random -minimum 100 -maximum 10000;
                     $StorageAvail=get-random -minimum 100 -maximum 10000;
                     $Storage="DC-"+$LocationsArray[$Stores+$StoreInd];
                     $WeekKey=get-date $StartDate -Format "yyyy-MM-dd";
                     $MPFile.writeline(($Stores+$StoreInd).ToString()+","+($Stores+$StoreInd)+","+$ItemInd+",0,"+$ItemInd+",1,1");
                   }
				    for($StoreInd=0;$StoreInd -lt $LDC2;$StoreInd++){
                     $B1Storage=get-random -minimum 100 -maximum 10000;
                     $B2Storage=get-random -minimum 100 -maximum 10000;
                     $StorageAvail=get-random -minimum 100 -maximum 10000;
                     $Storage="DC-"+$LocationsArray[$Stores+$LDC1+$StoreInd];
                     $WeekKey=get-date $StartDate -Format "yyyy-MM-dd";
                     $MPFile.writeline(($Stores+$LDC1+$StoreInd).ToString()+","+$($Stores+$LDC1+$StoreInd)+","+$ItemInd+",0,"+$ItemInd+",1,1");
                   }
               }

  $MPFile.close();
  $Proc=Get-Job;
	Stop-Job $Proc.InstanceId;
}

$generateMaterialNodeTimeParameters={
param($OutputDirectory,$StartDate,$Years,$ItemCount,$Version,$FileNamePrefix,$sliceId,$StartItemIntl,$EndItemIntl,$StartItemDom,$EndItemDom,$LocationsArray,$DomSuppliers,$IntlSuppliers,$Stores,$LDC1,$LDC2);
  $DFile=[System.IO.StreamWriter] ("$OutputDirectory\$FileNamePrefix-$($sliceId).csv");
	$bool=@("Y","N");
	$Inv=@(200,250,300);
	
	$DFile.writeline("Time.[FiscalWeekKey],Location.[LocationKey],Item.[ItemKey],Version.[VersionKey],SS Target Qty");
	[DateTime]$StartDate=get-date $StartDate;
	[DateTime]$EndDate=$StartDate.AddYears($Years);
	
	
       while($StartDate -lt $EndDate)
	{
	for($LocInd=0;$LocInd -lt ($Stores);$LocInd++)
       {
          for($ItemInd=$StartItemIntl;$ItemInd -lt $EndItemDom;$ItemInd++)
          {

                     $Inventory=get-random -minimum 100 -maximum 1000;
					 $ILT=600;
                     $SupplyChanged = get-random $bool;
                     $WeekKey=get-date $StartDate -format "yyyy-MM-dd";
                     $DFile.writeline($WeekKey+","+$LocInd+","+$ItemInd+",0,"+$ILT);
                     
          }
          
        }
		for($LocInd=$Stores;$LocInd -lt ($Stores+$LDC1+$LDC2);$LocInd++)
       {
          for($ItemInd=$StartItemIntl;$ItemInd -lt $EndItemIntl;$ItemInd++)
          {

                     $Inventory=get-random -minimum 100 -maximum 1000;
					 $ILT=600;
                     $SupplyChanged = get-random $bool;
                     $WeekKey=get-date $StartDate -format "yyyy-MM-dd";
                     $DFile.writeline($WeekKey+","+$LocInd+","+$ItemInd+",0,"+$ILT);
                     
          }
          
        }
        
         $weekcnt++;
        $StartDate=$StartDate.AddDays(7);
	}
	
$DFile.close();
$Proc=Get-Job;
	Stop-Job $Proc.InstanceId;
}
$generateMaterialNodeParameters={
	param($OutputDirectory,$StartDate,$Years,$ItemCount,$Version,$FileNamePrefix,$sliceId,$SupCanSupply,$LocationsArray,$LDC1,$LDC2,$Stores,$LocationHash,$CommonItems,$DomSuppliers,$IntlSuppliers,$StartItemIntl,$StartItemDom,$EndItemIntl,$EndItemDom);
	$DFile=[System.IO.StreamWriter] ("$OutputDirectory\$FileNamePrefix-$($sliceId).csv");
	$bool=@("Y","N");
	$itemval=0;
	
	$DFile.writeline("Location.[LocationKey],Item.[ItemKey],Version.[VersionKey],Constant Target Inventory,Constant WOS Target,Infinite Inventory,Material Segment,Max Stock,No Carry,Safety Stock Priority,Storage");

	
	   for($LocInd=0;$LocInd -lt $IntlSuppliers;$LocInd++)
       {
          for($ItemInd=$StartItemIntl;$ItemInd -lt $EndItemIntl;$ItemInd++)
          {

                 $Location=$LocationsArray[$Stores+$LDC1+$LDC2+$LocInd];
				 
                 $DFile.writeline($LocationHash.Get_Item([Int]$Location).ToString()+","+$ItemInd+",0,,,1,,,,,");
                     
                  
          } 
	    }
		 for($LocInd=0;$LocInd -lt $DomSuppliers;$LocInd++)
       {
          for($ItemInd=$StartItemDom;$ItemInd -lt $EndItemDom;$ItemInd++)
          {

                 $Location=$LocationsArray[$Stores+$LDC1+$LDC2+$IntlSuppliers+$LocInd];
				
                $DFile.writeline($LocationHash.Get_Item([Int]$Location).ToString()+","+$ItemInd+",0,,,1,,,,,");
                              
          }
		 }
         
$DFile.close();
$Proc=Get-Job;
	Stop-Job $Proc.InstanceId;
}


$generateInventory={
	param($OutputDirectory,$StartDate,$Years,$ItemCount,$Version,$FileNamePrefix,$sliceId,$StartItemIntl,$EndItemIntl,$StartItemDom,$EndItemDom,$LocationsArray,$DomSuppliers,$IntlSuppliers,$Stores,$LDC1,$LDC2);
  $DFile=[System.IO.StreamWriter] ("$OutputDirectory\$FileNamePrefix-$($sliceId).csv");
	$bool=@("Y","N");
	$Inv=@(200,250,300);

	$DFile.writeline("Time.[FiscalWeekKey],Location.[LocationKey],Item.[ItemKey],Version.[VersionKey],BOH,Expected Receipts,Inventory,Supply Changed");
	[DateTime]$StartDate=get-date $StartDate;
	[DateTime]$EndDate=$StartDate.AddDays(21);
	
	  $BOH=300;
       $ExpectedReceipts=" ";
       $Cnt=0;
	   $weekcnt=1;
       while($StartDate -lt $EndDate)
	{
	for($LocInd=0;$LocInd -lt ($Stores);$LocInd++)
       {
          for($ItemInd=$StartItemIntl;$ItemInd -lt $EndItemDom;$ItemInd++)
          {

                     $Inventory=get-random -minimum 100 -maximum 1000;
					 $ILT=600;
                     $SupplyChanged = get-random $bool;
                     $WeekKey=get-date $StartDate -format "yyyy-MM-dd";
                     $DFile.writeline($WeekKey+","+$LocInd+","+$ItemInd+",0,"+$BOH+","+$ExpectedReceipts+",,");
                     
          }
          
        }
		for($LocInd=$Stores;$LocInd -lt ($Stores+$LDC1+$LDC2);$LocInd++)
       {
          for($ItemInd=$StartItemIntl;$ItemInd -lt $EndItemIntl;$ItemInd++)
          {

                     $Inventory=get-random -minimum 100 -maximum 1000;
					 $ILT=600;
                     $SupplyChanged = get-random $bool;
                     $WeekKey=get-date $StartDate -format "yyyy-MM-dd";
                     $DFile.writeline($WeekKey+","+$LocInd+","+$ItemInd+",0,"+$BOH+","+$ExpectedReceipts+",,");
                     
          }
          
        }
        $BOH=" ";
        $ExpectedReceipts=100;
        $Cnt++;
        if($Cnt -gt 2)
        {
        $ExpectedReceipts=" ";
        }
         $weekcnt++;
        $StartDate=$StartDate.AddDays(7);
	}
	
	
$DFile.close();
$Proc=Get-Job;
	Stop-Job $Proc.InstanceId;
}
$generateCapacityGraphPlannedWIP={
	param($OutputDirectory,$StartDate,$Years,$Locations,$Activities,$ItemCount,$Version,$Transports,$Resources,$FileNamePrefix,$sliceId,$WithKey,$StartLoc,$EndLoc);
	$MPFile=[System.IO.StreamWriter] ("$OutputDirectory\$FileNamePrefix-$($sliceId).csv");
	[DateTime]$StartDate=get-date $StartDate;
	[DateTime]$EndDate=$StartDate.AddYears($Years);
    if(!($WithKey -eq 0))
    {
    $MPFile.writeline("Time.[TimeKey],Location.[LocationKey],Activity.[ActivityKey],Item.[ItemKey],Version.[Version],Resource.[ResourceKey],Transport.[TransportKey],Product.[ProductKey],Capacity Consumption Planned WIP");
      while($StartDate -lt $EndDate){
       for($LocInd=$StartLoc;$LocInd -lt $EndLoc;$LocInd++)
       {
          for($ItemInd=0;$ItemInd -lt $ItemCount;$ItemInd++)
          {
               for($ActInd=0;$ActInd -lt $Activities;$ActInd++)
               {
                 for($ResInd=0;$ResInd -lt $Resources;$ResInd++){
                   for($TransInd=0;$TransInd -lt $Transports;$TransInd++)
                   {
                     $MPPWip=get-random -minimum 100 -maximum 1000;
                     $WeekKey=get-date $StartDate -Format "yyyy-MM-dd";
                     $MPFile.writeline($WeekKey+","+$LocInd.ToString()+","+$ActInd+","+$ItemInd+",0,"+$ResInd+","+$TransInd+","+$ItemInd+","+$MPPWip);
                   }
                   }
               }
          }
        }
        $StartDate=$StartDate.AddDays(7);
        }
    }
    else
    {
      $MPFile.writeline("Location.[Location],Activity.[Activity],Item.[Item],Version.[Version],Resource.[Resource],Transport.[Transport],Product.[Product],Capacity Consumption Planned WIP");
      while($StartDate -lt $EndDate){
       for($LocInd=$StartLoc;$LocInd -lt $EndLoc;$LocInd++)
       {
          for($ItemInd=0;$ItemInd -lt $ItemCount;$ItemInd++)
          {
               for($ActInd=0;$ActInd -lt $Activities;$ActInd++)
               {
               for($ResInd=0;$ResInd -lt $Resources;$ResInd++){
                   for($TransInd=0;$TransInd -lt $Transports;$TransInd++)
                   {
                     $CCPWip=get-random -minimum 100 -maximum 10000;
                     $WeekKey=get-date $StartDate -Format "yyyy-MM-dd";
                     $MPFile.writeline($WeekKey+","+$LocInd.ToString()+","+$ActInd+","+$ItemInd+",CurrentWorkingView,"+$ResInd+","+$TransInd+","+$ItemInd+","+$CCPWip);
                   }
                   }
               }
          }
        }
        $StartDate=$StartDate.AddDays(7);
        }
    }
  $MPFile.close();
  $Proc=Get-Job;
  Stop-Job $Proc.InstanceId;
}
$generateMaterialProductionGraphPlannedWIP={
	param($OutputDirectory,$ItemCount,$Transports,$StartDate,$FileNamePrefix,$sliceId,$LocationsArray,$Stores,$ActivityHash,$LocationHash,$SupCanSupply,$LDC1,$LDC2,$IntlSuppliers,$DomSuppliers,$Slices,$StartItemIntl,$EndItemIntl,$StartItemDom,$EndItemDom);
	$MPFile=[System.IO.StreamWriter] ("$OutputDirectory\$FileNamePrefix-$($sliceId).csv");
	[DateTime]$StartDate=get-date $StartDate;
	[DateTime]$EndDate=$StartDate.AddDays(28);
	$MPVal=@(25,75);
    
    $MPFile.writeline("Time.[FiscalWeekKey],Location.[LocationKey],Activity.[ActivityKey],Item.[ItemKey],Version.[VersionKey],Transport.[TransportKey],Product.[ProductKey],Material Production Planned WIP");
     $weekcnt=1;
	 		  
		while($StartDate -lt $EndDate){
	  for($ActInd=0;$ActInd -lt ($IntlSuppliers*$LDC1);$ActInd++)
		{
		
		    for($ItemInd=$StartItemIntl;$ItemInd -lt $EndItemIntl;$ItemInd++)
			{

			  for($TransInd=0;$TransInd -lt $Transports;$TransInd++)
			  {
			  $mppw=get-random $MPVal;
			  $Loc=$ActivityHash[$ActInd] -split "-";
			  $Location=$Loc[2];
			  $WeekKey=get-date $StartDate -Format "yyyy-MM-dd";
              $MPFile.writeline($WeekKey.ToString()+","+$LocationHash.Get_Item([Int]$Location)+","+$ActInd+","+$ItemInd+",0,"+$TransInd+","+$ItemInd+","+$mppw);
	
			  }
			  
			}

		}
	    
		
		for($ActInd=($IntlSuppliers*$LDC1);$ActInd -lt $IntlSuppliers*$LDC1+2*$Stores;$ActInd++) 
		{
		
		    for($ItemInd=$StartItemIntl;$ItemInd -lt $EndItemDom;$ItemInd++)
			{
			
			  for($TransInd=0;$TransInd -lt $Transports;$TransInd++)
			  {
			  
			  $mppw=get-random $MPVal;
			  $Loc=$ActivityHash[$ActInd] -split "-";
			  $Location=$Loc[2];
			  $WeekKey=get-date $StartDate -Format "yyyy-MM-dd";
              $MPFile.writeline($WeekKey.ToString()+","+$LocationHash.Get_Item([Int]$Location)+","+$ActInd+","+$ItemInd+",0,"+$TransInd+","+$ItemInd+","+$mppw);
	
			  }
			  
			}
			
		}
		for($ActInd=($IntlSuppliers*$LDC1+2*$Stores);$ActInd -lt $IntlSuppliers*$LDC1+2*$Stores+2*$LDC2;$ActInd++) 
		{
		
		    for($ItemInd=$StartItemIntl;$ItemInd -lt $EndItemIntl;$ItemInd++)
			{
			
			  for($TransInd=0;$TransInd -lt $Transports;$TransInd++)
			  {
			  
			  $mppw=get-random $MPVal;
			  $Loc=$ActivityHash[$ActInd] -split "-";
			  $Location=$Loc[2];
			  $WeekKey=get-date $StartDate -Format "yyyy-MM-dd";
              $MPFile.writeline($WeekKey.ToString()+","+$LocationHash.Get_Item([Int]$Location)+","+$ActInd+","+$ItemInd+",0,"+$TransInd+","+$ItemInd+","+$mppw);
	
			  }
			  
			}
			
		}
	    for($ActInd=$IntlSuppliers*$LDC1+2*$LDC2+2*$Stores;$ActInd -lt $IntlSuppliers*$LDC1+2*$LDC2+2*$Stores+$DomSuppliers*$LDC2;$ActInd++) 
		{
		
		    for($ItemInd=$StartItemDom;$ItemInd -lt $EndItemDom;$ItemInd++)
			{
			
			  for($TransInd=0;$TransInd -lt $Transports;$TransInd++)
			  {
			  
			  $mppw=get-random $MPVal;
			  $Loc=$ActivityHash[$ActInd] -split "-";
			  $Location=$Loc[2];
			  $WeekKey=get-date $StartDate -Format "yyyy-MM-dd";
              $MPFile.writeline($WeekKey.ToString()+","+$LocationHash.Get_Item([Int]$Location)+","+$ActInd+","+$ItemInd+",0,"+$TransInd+","+$ItemInd+","+$mppw);
	
			  }
			  
			}
			
		}
		
	  $StartDate=$StartDate.AddDays(7);
        }
	
  $MPFile.close();
  $Proc=Get-Job;
	Stop-Job $Proc.InstanceId;
}

$generateCapacityAvailability={
   param($OutputDirectory,$StartDate,$Years,$Version,$Resources,$FileNamePrefix,$sliceId,$LocationsArray,$IntlSuppliers,$DomSuppliers,$Stores,$ResourceHash,$LDC1,$LDC2,$LocationHash,$ResActHash,$FindActKeyHash);
   $CapFile=[System.IO.StreamWriter] ("$OutputDirectory\$FileNamePrefix-$($sliceId).csv");
	$rand1=@(35000,45000);
	$rand2=@(800000,1000000);
	$rand3=@(15000,20000);
	$CapFile.writeline("Time.[FiscalWeekKey],Location.[LocationKey],Version.[VersionKey],Resource.[ResourceKey],Capacity Availability,Capacity Changed,Overtime_1,Overtime_2");
	[DateTime]$StartDate=get-date $StartDate;
	[DateTime]$EndDate=$StartDate.AddYears($Years);
	
	  while($StartDate -lt $EndDate)
	{
        for($ResInd=0;$ResInd -lt $ResourceHash.count;$ResInd++)
		{
		
		 $acty=$ResActHash.Get_Item($Res);
			  
			   $actind=$FindActKeyHash.Get_Item([string]$acty);
		       $Location=$acty -split "-";
		 $WeekKey=get-date $StartDate -Format "yyyy-MM-dd";
		 $LocKey=[Int]$Location[2];
		 if($LocKey -ge 6000 -and $LocKey -lt 7000)
         {
          $capavail=get-random $rand1;
         }elseif($LocKey -ge 5000 -and $LocKey -lt 6000)
         {
             $capavail=get-random $rand2;
          }else
		  {
		  $capavail=get-random $rand3;
		  }
         $CapFile.writeline($WeekKey+","+$LocationHash.Get_Item($LocKey)+",0,"+$ResInd+","+$capavail+",,");
		}
	
        $StartDate=$StartDate.AddDays(7);
	}
	
$CapFile.close();
$Proc=Get-Job;
Stop-Job $Proc.InstanceId;
}
$generateActivityParameters={
	param($OutputDirectory,$Transports,$ItemCount,$FileNamePrefix,$sliceId,$WithKey,$LocationsArray,$Stores,$ActivityHash,$SupCanSupply,$LDC1,$LDC2,$IntlSuppliers,$DomSuppliers,$Slices,$CommonItems,$StartItemIntl,$StartItemDom,$EndItemIntl,$EndItemDom);
	$ActFile=[System.IO.StreamWriter] ("$OutputDirectory\$FileNamePrefix-$($sliceId).csv");
	
	
	$ActFile.writeline("Activity.[ActivityKey],Version.[VersionKey],Transport.[TransportKey],Product.[ProductKey],Activity Lead Time,Solver Activity End Date,Solver Activity Start Date");
    
		 for($ActInd=0;$ActInd -lt ($IntlSuppliers*$LDC1);$ActInd++)
		{
		 
		    for($ItemInd=$StartItemIntl;$ItemInd -lt $EndItemIntl;$ItemInd++)
			{

			  for($TransInd=0;$TransInd -lt $Transports;$TransInd++)
			  {
			  
			  $Loc=$ActivityHash[$ActInd] -split "-";
			  $Location=$Loc[2];
			  $LocKey=[Int]$Location;
     $ActFile.writeline($ActInd.ToString()+",0,"+$TransInd+","+$ItemInd+",1,,");

			  }
			  
			}

		}
	    
		
		for($ActInd=($IntlSuppliers*$LDC1);$ActInd -lt ($IntlSuppliers*$LDC1+2*$Stores);$ActInd++) 
		{
		
		    for($ItemInd=$StartItemIntl;$ItemInd -lt $EndItemDom;$ItemInd++)
			{
			
			  for($TransInd=0;$TransInd -lt $Transports;$TransInd++)
			  {
			  
			  $Loc=$ActivityHash[$ActInd] -split "-";
			  $Location=$Loc[2];
			  $LocKey=[Int]$Location;
     $ActFile.writeline($ActInd.ToString()+",0,"+$TransInd+","+$ItemInd+",1,,");

			  }
			  
			}
			
		}
		for($ActInd=($IntlSuppliers*$LDC1+2*$Stores);$ActInd -lt ($IntlSuppliers*$LDC1+2*$Stores+2*$LDC2);$ActInd++) 
		{
		
		    for($ItemInd=$StartItemIntl;$ItemInd -lt $EndItemIntl;$ItemInd++)
			{
			
			  for($TransInd=0;$TransInd -lt $Transports;$TransInd++)
			  {
			  
			  $Loc=$ActivityHash[$ActInd] -split "-";
			  $Location=$Loc[2];
			  $LocKey=[Int]$Location;
                   $ActFile.writeline($ActInd.ToString()+",0,"+$TransInd+","+$ItemInd+",1,,");

			  }
			  
			}
			
		}
	    for($ActInd=$IntlSuppliers*$LDC1+2*$LDC2+2*$Stores;$ActInd -lt $IntlSuppliers*$LDC1+2*$LDC2+2*$Stores+$DomSuppliers*$LDC2;$ActInd++) 
		{
		
		    for($ItemInd=$StartItemDom;$ItemInd -lt $EndItemDom;$ItemInd++)
			{
			
			  for($TransInd=0;$TransInd -lt $Transports;$TransInd++)
			  {
			  
			  $Loc=$ActivityHash[$ActInd] -split "-";
			  $Location=$Loc[2];
			  $LocKey=[Int]$Location;
                  $ActFile.writeline($ActInd.ToString()+",0,"+$TransInd+","+$ItemInd+",1,,");

			  }
			  
			}
			
		}
		
          $ActFile.close();
          $Proc=Get-Job;
	Stop-Job $Proc.InstanceId;
}
$generateDemand =
{

	param($OutputDirectory,$StartDate,$Years,$Demands,$Customers,$ItemCount,$FileNamePrefix,$sliceId,$StartItemIntl,$EndItemIntl,$StartItemDom,$EndItemDom,$LocationsArray,$DomSuppliers,$IntlSuppliers,$Stores,$LDC1,$LDC2);
	
	$bool=@("0","1");
	$DFile=[System.IO.StreamWriter] ("$OutputDirectory\$FileNamePrefix-$($sliceId).csv");
	$dem=@(10,50,100);
	
	$DFile.writeline("Time.[FiscalWeekKey],Location.[LocationKey],Demand.[DemandKey],Customer.[CustomerKey],Item.[ItemKey],Version.[VersionKey],Demand Build Ahead Lmit,Demand Build Late Limit,Demand Priority,Demand Quantity,Demand Trace,Incremental_Allowed,Quantity Fulfilled,Quantity Incrementally fulfilled,Demand Chunk Measure");
	[DateTime]$StartDate=get-date $StartDate;
	[DateTime]$EndDate=$StartDate.AddDays(21);
	
	     while($StartDate -lt $EndDate)
	{
	  for($LocInd=0;$LocInd -lt 5;$LocInd++) #replace 5 with $Stores
       {
          for($ItemInd=$StartItemIntl;$ItemInd -lt $EndItemDom;$ItemInd++)
          {
               
                     for($DemInd=0;$DemInd -lt $Demands;$DemInd++){

                     for($CustInd=0;$CustInd -lt $Customers;$CustInd++){
                     
                     $DemandQuantity=get-random $dem;
                     $WeekKey=get-date $StartDate -format "yyyy-MM-dd";
                     $DFile.writeline($WeekKey+","+$LocInd+","+$DemInd+","+$CustInd+","+$ItemInd+",0,3,3,1,"+$DemandQuantity+",,,,,"+$sliceId);
                     
                     }
                     }
          }
          }
		  $weekcnt++;
          $StartDate=$StartDate.AddDays(7);
        }
	
	
	
$DFile.close(); 
$Proc=Get-Job;
	Stop-Job $Proc.InstanceId;
}
$generateCapacityConsumptionGraph={
	param($OutputDirectory,$ItemCount,$Transports,$FileNamePrefix,$sliceId,$LocationsArray,$Stores,$LDC1,$LDC2,$ActivityHash,$ResourceHash,$LocationHash,$SupCanSupply,$Slices,$ResActHash,$IntlSuppliers,$DomSuppliers,$StartItemIntl,$StartItemDom,$EndItemIntl,$EndItemDom,$FindActKeyHash,$FindResKeyHash);
	$bool=@("Y","N");
	$Cat=0;
    $MPFile=[System.IO.StreamWriter] ("$OutputDirectory\$FileNamePrefix-$($sliceId).csv");
    
      $MPFile.writeline("Location.[LocationKey],Activity.[ActivityKey],Version.[VersionKey],Resource.[ResourceKey],Transport.[TransportKey],Product.[ProductKey],Capacity Category,Capacity Consumption Graph Association,Capacity Consumption Qty Per,Capacity Graph Priority");
   	for($ActInd=0;$ActInd -lt ($IntlSuppliers*$LDC1);$ActInd++)  
	{
	   for($ItemInd=$StartItemIntl;$ItemInd -lt $EndItemIntl;$ItemInd++)
			{
			
			
			  for($TransInd=0;$TransInd -lt $Transports;$TransInd++)
			  {
			 	  $Activity=$ActivityHash.Get_Item([Int]$actind); 
			    
			   
			   $acty=$ResActHash.Get_Item($Activity);
			  $location=$Activity -split "-";
			  for($resind=0;$resind -lt $acty.count;$resind++){
		       $reskey=$FindResKeyHash.Get_Item($acty[$resind]);
	           $MPFile.writeline($LocationHash.Get_Item([Int]$location[2]).ToString()+","+$ActInd+","+"0"+","+$reskey+","+$TransInd+","+$ItemInd+",,1,1,1");
               #$MPFile.writeline($acty[$resind]);
			   }
	  
			  }
			  
			}
	
			 
	
	}
	
	for($ActInd=($IntlSuppliers*$LDC1);$ActInd -lt ($IntlSuppliers*$LDC1)+2*$Stores;$ActInd++)
		{
		
		    for($ItemInd=$StartItemIntl;$ItemInd -lt $EndItemDom;$ItemInd++)
			{
			
			  for($TransInd=0;$TransInd -lt $Transports;$TransInd++)
			  {
			   $Activity=$ActivityHash.Get_Item([Int]$actind); 
			   $acty=$ResActHash.Get_Item($Activity);
			   $location=$Activity -split "-";
			   for($resind=0;$resind -lt $acty.count;$resind++){
		       $reskey=$FindResKeyHash.Get_Item($acty[$resind]);
	           $MPFile.writeline($LocationHash.Get_Item([Int]$location[2]).ToString()+","+$ActInd+","+"0"+","+$reskey+","+$TransInd+","+$ItemInd+",,1,1,1");
			   }
			  
			}
			
		}
		}
		
			for($ActInd=($IntlSuppliers*$LDC1+2*$Stores);$ActInd -lt ($IntlSuppliers*$LDC1+2*$Stores)+$LDC2*2;$ActInd++)
		{
		
		    for($ItemInd=$StartItemIntl;$ItemInd -lt $EndItemIntl;$ItemInd++)
			{
			
			  for($TransInd=0;$TransInd -lt $Transports;$TransInd++)
			  {
			   $Activity=$ActivityHash.Get_Item([Int]$actind); 
			   $acty=$ResActHash.Get_Item($Activity);
			   $location=$Activity -split "-";
			   for($resind=0;$resind -lt $acty.count;$resind++){
		       $reskey=$FindResKeyHash.Get_Item($acty[$resind]);
	           $MPFile.writeline($LocationHash.Get_Item([Int]$location[2]).ToString()+","+$ActInd+","+"0"+","+$reskey+","+$TransInd+","+$ItemInd+",,1,1,1");
			   }
			  
			}
			
		}
		}
	    for($ActInd=($IntlSuppliers*$LDC1+$Stores*2+$LDC2*2);$ActInd -lt ($IntlSuppliers*$LDC1+2*$Stores)+$LDC2*2+$DomSuppliers*$LDC2;$ActInd++)
		{
		
		    for($ItemInd=$StartItemDom;$ItemInd -lt $EndItemDom;$ItemInd++)
			{
			
			  for($TransInd=0;$TransInd -lt $Transports;$TransInd++)
			  {
			   $Activity=$ActivityHash.Get_Item([Int]$actind); 
			   $acty=$ResActHash.Get_Item($Activity);
			   $location=$Activity -split "-";
			   for($resind=0;$resind -lt $acty.count;$resind++){
		       $reskey=$FindResKeyHash.Get_Item($acty[$resind]);
	           $MPFile.writeline($LocationHash.Get_Item([Int]$location[2]).ToString()+","+$ActInd+","+"0"+","+$reskey+","+$TransInd+","+$ItemInd+",,1,1,1");
			   }
			  
			}
			
		}
		}
	
  $MPFile.close();
  $Proc=Get-Job;
  Stop-Job $Proc.InstanceId;

}
$generateMaterialConsumptionGraph={
	param($OutputDirectory,$ItemCount,$Transports,$FileNamePrefix,$sliceId,$LocationsArray,$Stores,$ActivityHash,$LocationHash,$SupCanSupply,$LDC1,$LDC2,$IntlSuppliers,$DomSuppliers,$Slices,$StartItemIntl,$EndItemIntl,$StartItemDom,$EndItemDom);
	$bool=@("Y","N");
    $MPFile=[System.IO.StreamWriter] ("$OutputDirectory\$FileNamePrefix-$($sliceId).csv");
   
	
    $MPFile.writeline("Location.[LocationKey],Activity.[ActivityKey],Item.[ItemKey],Version.[VersionKey],Transport.[TransportKey],Product.[ProductKey],Material Consumption Graph Association,Material Consumption Qty Per");
    
		 $StartItem=0;$Iter=0;
		for($ActInd=0;$ActInd -lt ($IntlSuppliers*$LDC1);$ActInd++)
		{
		 
		    for($ItemInd=$StartItemIntl;$ItemInd -lt $EndItemIntl;$ItemInd++)
			{

			  for($TransInd=0;$TransInd -lt $Transports;$TransInd++)
			  {
			  
			  $Loc=$ActivityHash[$ActInd] -split "-";
			  $Location=$Loc[1];
			  $LocKey=[Int]$Location;
			   $MPFile.writeline($LocationHash.Get_Item($LocKey).ToString()+","+$ActInd+","+$ItemInd+",0,"+$TransInd+","+$ItemInd+","+"1,1");

			  }
			  
			}

		}
	    
		
		for($ActInd=($IntlSuppliers*$LDC1);$ActInd -lt $IntlSuppliers*$LDC1+2*$Stores;$ActInd++) 
		{
		
		    for($ItemInd=$StartItemIntl;$ItemInd -lt $EndItemDom;$ItemInd++)
			{
			
			  for($TransInd=0;$TransInd -lt $Transports;$TransInd++)
			  {
			  
			  $Loc=$ActivityHash[$ActInd] -split "-";
			  $Location=$Loc[1];
			  $LocKey=[Int]$Location;
			    $MPFile.writeline($LocationHash.Get_Item($LocKey).ToString()+","+$ActInd+","+$ItemInd+",0,"+$TransInd+","+$ItemInd+","+"1,1");

			  }
			  
			}
			
		}
		for($ActInd=($IntlSuppliers*$LDC1+2*$Stores);$ActInd -lt $IntlSuppliers*$LDC1+2*$Stores+2*$LDC2;$ActInd++) 
		{
		
		    for($ItemInd=$StartItemIntl;$ItemInd -lt $EndItemIntl;$ItemInd++)
			{
			
			  for($TransInd=0;$TransInd -lt $Transports;$TransInd++)
			  {
			  
			  $Loc=$ActivityHash[$ActInd] -split "-";
			  $Location=$Loc[1];
			  $LocKey=[Int]$Location;
			    $MPFile.writeline($LocationHash.Get_Item($LocKey).ToString()+","+$ActInd+","+$ItemInd+",0,"+$TransInd+","+$ItemInd+","+"1,1");

			  }
			  
			}
			
		}
	    for($ActInd=$IntlSuppliers*$LDC1+2*$LDC2+2*$Stores;$ActInd -lt $IntlSuppliers*$LDC1+2*$LDC2+2*$Stores+$DomSuppliers*$LDC2;$ActInd++) 
		{
		
		    for($ItemInd=$StartItemDom;$ItemInd -lt $EndItemDom;$ItemInd++)
			{
			
			  for($TransInd=0;$TransInd -lt $Transports;$TransInd++)
			  {
			  
			  $Loc=$ActivityHash[$ActInd] -split "-";
			  $Location=$Loc[1];
			  $LocKey=[Int]$Location;
			   $MPFile.writeline($LocationHash.Get_Item($LocKey).ToString()+","+$ActInd+","+$ItemInd+",0,"+$TransInd+","+$ItemInd+","+"1,1");

			  }
			  
			}
			
		}
    
  $MPFile.close();
  $Proc=Get-Job;
	Stop-Job $Proc.InstanceId;
}

$generateMaterialProductionGraph={

##Didnt write for the keys
	param($OutputDirectory,$ItemCount,$Transports,$FileNamePrefix,$sliceId,$LocationsArray,$Stores,$ActivityHash,$LocationHash,$SupCanSupply,$LDC1,$LDC2,$IntlSuppliers,$DomSuppliers,$Slices,$StartItemIntl,$EndItemIntl,$StartItemDom,$EndItemDom);
	$bool=@("0","1");
	
    $MPFile=[System.IO.StreamWriter] ("$OutputDirectory\$FileNamePrefix-$($sliceId).csv");
	
   
    $MPFile.writeline("Location.[LocationKey],Activity.[ActivityKey],Item.[ItemKey],Version.[VersionKey],Transport.[TransportKey],Product.[ProductKey],Material Production Graph Association,Material Production Min Qty,Material Production Multiple Qty,Material Production Priority,Material Production Qty Per,No Build");
    
	
		
		for($ActInd=0;$ActInd -lt ($IntlSuppliers*$LDC1);$ActInd++)
		{
		 
		    for($ItemInd=$StartItemIntl;$ItemInd -lt $EndItemIntl;$ItemInd++)
			{

			  for($TransInd=0;$TransInd -lt $Transports;$TransInd++)
			  {
			  
			  $Loc=$ActivityHash[$ActInd] -split "-";
			  $Location=$Loc[2];
			  $LocKey=[Int]$Location;
			  $MPFile.writeline($LocationHash.Get_Item($LocKey).ToString()+","+$ActInd+","+($ItemInd)+",0,"+$TransInd+","+($ItemInd)+","+"1"+",,,"+"1"+","+"1"+",");

			  }
			  
			}

		}
	    
		
		for($ActInd=($IntlSuppliers*$LDC1);$ActInd -lt $IntlSuppliers*$LDC1+2*$Stores;$ActInd++) 
		{
		
		    for($ItemInd=$StartItemIntl;$ItemInd -lt $EndItemDom;$ItemInd++)
			{
			
			  for($TransInd=0;$TransInd -lt $Transports;$TransInd++)
			  {
			  
			  $Loc=$ActivityHash[$ActInd] -split "-";
			  $Location=$Loc[2];
			  $LocKey=[Int]$Location;
			   $MPFile.writeline($LocationHash.Get_Item($LocKey).ToString()+","+$ActInd+","+($ItemInd)+",0,"+$TransInd+","+($ItemInd)+","+"1"+",,,"+"1"+","+"1"+",");

			  }
			  
			}
			
		}
		for($ActInd=($IntlSuppliers*$LDC1+2*$Stores);$ActInd -lt $IntlSuppliers*$LDC1+2*$Stores+2*$LDC2;$ActInd++) 
		{
		
		    for($ItemInd=$StartItemIntl;$ItemInd -lt $EndItemIntl;$ItemInd++)
			{
			
			  for($TransInd=0;$TransInd -lt $Transports;$TransInd++)
			  {
			  
			  $Loc=$ActivityHash[$ActInd] -split "-";
			  $Location=$Loc[2];
			  $LocKey=[Int]$Location;
			   $MPFile.writeline($LocationHash.Get_Item($LocKey).ToString()+","+$ActInd+","+$ItemInd+",0,"+$TransInd+","+$ItemCount+","+"1"+",,,"+"1"+","+"1"+",");

			  }
			  
			}
			
		}
	    for($ActInd=$IntlSuppliers*$LDC1+2*$LDC2+2*$Stores;$ActInd -lt $IntlSuppliers*$LDC1+2*$LDC2+2*$Stores+$DomSuppliers*$LDC2;$ActInd++) 
		{
		
		    for($ItemInd=$StartItemDom;$ItemInd -lt $EndItemDom;$ItemInd++)
			{
			
			  for($TransInd=0;$TransInd -lt $Transports;$TransInd++)
			  {
			  
			  $Loc=$ActivityHash[$ActInd] -split "-";
			  $Location=$Loc[2];
			  $LocKey=[Int]$Location;
			   $MPFile.writeline($LocationHash.Get_Item($LocKey).ToString()+","+$ActInd+","+$ItemInd+",0,"+$TransInd+","+$ItemInd+","+"1"+",,,"+"1"+","+"1"+",");

			  }
			  
			}
			
		}
		
		
    
    
  $MPFile.close();
  $Proc=Get-Job;
	Stop-Job $Proc.InstanceId;
}
function generateActivities
{
	param($Activities,$LocationsArray,$DomSuppliers,$IntlSuppliers,$Stores,$LDC1,$LDC2);
    
	$ActFile=[System.IO.StreamWriter]("$OutputDirectory\Dimension.Activities.csv");
	$ActFile.writeline("Activity.[ActivityKey],Activity.[Activity],Activity.[ActivitySubGroupKey],Activity.[Activity Sub Group],Activity.[ActivityGroupKey],Activity.[Activity Group]");
    $ActInd=0;	
	$StartLDC1=0;
	
	## International Suppliers to Level 1 DC Connection;
	for($LocInd=0;$LocInd -lt ($IntlSuppliers);$LocInd++)  
	{
	for($DCInd=0;$DCInd -lt $LDC1;$DCInd++){
	$ActSubG=[math]::floor($ActInd/5);
    $ActG=[math]::floor($ActInd/10);
	$Activity="Act-"+$LocationsArray[$LDC1+$LDC2+$Stores+$LocInd]+"-"+$LocationsArray[$Stores+$DCInd];
    $ActFile.writeline($ActInd.ToString()+","+$Activity+","+$ActSubG+","+"ActSubGrp-"+$ActSubG+","+$ActG+","+"ActGroup-"+$ActG);
    $ActivityHash.Set_Item($ActInd,$Activity);
	##Linking resources with activity 
	$Res1="Res-"+$LocationsArray[$LDC1+$LDC2+$Stores+$LocInd]+"-"+$LocationsArray[$Stores+$DCInd];
	$Res2="Res-"+$LocationsArray[$Stores+$DCInd];
	$Resarr=@($Res1,$Res2);
	$ResActHash.Set_Item($Activity,$Resarr);
	$FindActKeyHash.Set_Item($Activity,$ActInd);
    $ActInd++;
    }
	}
	
	##Level 2 DC to Stores Connection...
	$StartStore=0;
	
	for($LocInd=0;$LocInd -lt $LDC2;$LocInd++)
	{
	  for($StoreInd=0;$StoreInd -lt 2*($Stores/$LDC2);$StoreInd++){
	$ActSubG=[math]::floor($ActInd/5);
    $ActG=[math]::floor($ActInd/10);
    $Activity="Act-"+$LocationsArray[$Stores+$LDC1+$LocInd]+"-"+($LocationsArray[(($StartStore+$StoreInd)%$Stores)]);
    $ActFile.writeline($ActInd.ToString()+","+$Activity+","+$ActSubG+","+"ActSubGrp-"+$ActSubG+","+$ActG+","+"ActGroup-"+$ActG);
    $ActivityHash.Set_Item($ActInd,$Activity);
	##Linking resources with activity
	$Res1="Res-"+$LocationsArray[$Stores+$LDC1+$LocInd]+"-"+($LocationsArray[(($StartStore+$StoreInd)%$Stores)]);
	$Res2="Res-"+$LocationsArray[$Stores+$LDC1+$LocInd];
	$Res3="Res-"+$LocationsArray[$Stores+$LDC1+$LocInd]+"-I";
	$Res4="Res-"+($LocationsArray[(($StartStore+$StoreInd)%$Stores)])+"-O";
	$Resarr=@($Res1,$Res2,$Res3,$Res4);
	$ResActHash.Set_Item($Activity,$Resarr);
    $FindActKeyHash.Set_Item($Activity,$ActInd);
    $ActInd++;
    
    }
	$StartStore+=($Stores/$LDC2);
	}
	#>
	##Level 1 DC to Level 2 DC 
	$LeftLoc=($LDC2/2)%($LDC1/2);
	$LeftLoc=$LeftLoc/2;
	$AppendInd=$LeftLoc;
	$StartDc=0;
    for($LocInd=0;$LocInd -lt ($LDC1);$LocInd++)
    {
	  for($DCInd=0;$DCInd -lt [math]::floor($LDC2/$LDC1)+$AppendInd;$DCInd++){
    $Activity="Act-"+$LocationsArray[$Stores+$LocInd]+"-"+$LocationsArray[$Stores+$LDC1+$StartDc+$DCInd];
    $ActSubG=[math]::floor($ActInd/5);
    $ActG=[math]::floor($ActInd/10);
    $ActFile.writeline($ActInd.ToString()+","+$Activity+","+$ActSubG+","+"ActSubGrp-"+$ActSubG+","+$ActG+","+"ActGroup-"+$ActG);
    $ActivityHash.Set_Item($ActInd,$Activity);
		$FindActKeyHash.Set_Item($Activity,$ActInd);
		$Res1="Res-"+$LocationsArray[$Stores+$LocInd]+"-"+$LocationsArray[$Stores+$LDC1+$StartDc+$DCInd];
	$Res2="Res-"+$LocationsArray[$Stores+$LocInd];
	$Res3="Res-"+$LocationsArray[$Stores+$LocInd]+"-O";
	$Res4="Res-"+$LocationsArray[$Stores+$LocInd]+"-I";
	$Res5="Res-"+$LocationsArray[$Stores+$LDC1+$StartDc+$DCInd]
    $Resarr=@($Res1,$Res2,$Res3,$Res4,$Res5);
	$ResActHash.Set_Item($Activity,$Resarr);
    $ActInd++;
    }
	
	$StartDc=$StartDc+[math]::floor($LDC2/$LDC1)+$AppendInd;
	$LeftLoc=$LeftLoc-2;
	if($LeftLoc -lt 0)
	  {
	  $AppendInd=0;
	  }
	  if($LocInd -eq $LDC1/2-1)
	  {
	    $LeftLoc=($LDC2/2)%($LDC1/2);
	$LeftLoc=$LeftLoc/2;
	$AppendInd=$LeftLoc;
	$StartDc=0;
	  }
    }
	
	$LeftLoc=($LDC2/2)%($LDC1/2);
	$LeftLoc=$LeftLoc/2;
	$AppendInd=$LeftLoc;
	$StartDc=0;
    for($LocInd=0;$LocInd -lt ($LDC1);$LocInd++)
    {
	for($DCInd=0;$DCInd -lt [math]::floor($LDC2/$LDC1)+$AppendInd;$DCInd++){
    $Activity="Act-"+$LocationsArray[$Stores+$LocInd]+"-"+$LocationsArray[$Stores+$LDC1+($LDC2/2)+$StartDc+$DCInd];
    $ActSubG=[math]::floor($ActInd/5);
    $ActG=[math]::floor($ActInd/10);
    $ActFile.writeline($ActInd.ToString()+","+$Activity+","+$ActSubG+","+"ActSubGrp-"+$ActSubG+","+$ActG+","+"ActGroup-"+$ActG);
    $ActivityHash.Set_Item($ActInd,$Activity);
	$Res1="Res-"+$LocationsArray[$Stores+$LocInd]+"-"+$LocationsArray[$Stores+$LDC1+$StartDc+$DCInd];
	$Res2="Res-"+$LocationsArray[$Stores+$LocInd];
	$Res3="Res-"+$LocationsArray[$Stores+$LocInd]+"-O";
	$Res4="Res-"+$LocationsArray[$Stores+$LocInd]+"-I";
	$Res5="Res-"+$LocationsArray[$Stores+$LDC1+$StartDc+$DCInd]
    $Resarr=@($Res1,$Res2,$Res3,$Res4,$Res5);
	$ResActHash.Set_Item($Activity,$Resarr);
	$FindActKeyHash.Set_Item($Activity,$ActInd);
    $ActInd++;
    }
	
	$StartDc=$StartDc+[math]::floor($LDC2/$LDC1)+$AppendInd;
	$LeftLoc=$LeftLoc-2;
	if($LeftLoc -lt 0)
	  {
	  $AppendInd=0;
	  }
	   if($LocInd -eq $LDC1/2-1)
	  {
	$LeftLoc=($LDC2/2)%($LDC1/2);
	$LeftLoc=$LeftLoc/2;
	$AppendInd=$LeftLoc;
	$StartDc=0;
	  }
	  
    } 
	##Domestic Suppliers to RDC
	$StartStore=0;
	
	for($LocInd=0;$LocInd -lt ($DomSuppliers);$LocInd++)  
	{
	for($DCInd=0;$DCInd -lt $LDC2;$DCInd++){
	$ActSubG=[math]::floor($ActInd/5);
    $ActG=[math]::floor($ActInd/10);
	$Activity="Act-"+$LocationsArray[$LDC1+$LDC2+$Stores+$IntlSuppliers+$LocInd]+"-"+$LocationsArray[$Stores+$LDC1+$DCInd];
    $ActFile.writeline($ActInd.ToString()+","+$Activity+","+$ActSubG+","+"ActSubGrp-"+$ActSubG+","+$ActG+","+"ActGroup-"+$ActG);
    $ActivityHash.Set_Item($ActInd,$Activity);
	$FindActKeyHash.Set_Item($Activity,$ActInd);
    $Res1="Res-"+$LocationsArray[$LDC1+$LDC2+$Stores+$IntlSuppliers+$LocInd]+"-"+$LocationsArray[$Stores+$LDC1+$DCInd];
	$Resarr=@($Res1);
	$ResActHash.Set_Item($Activity,$Resarr);
    $ActInd++;
    }
	}
	$ActFile.close();
}
function generateDemands
{
	param($Demands);
	$DemandFile=[System.IO.StreamWriter]("$OutputDirectory\Dimension.Demands.csv")
	$DemandFile.writeline("Demand.[DemandKey],Demand.[Demand],Demand.[DemandSubGroupKey],Demand.[Demand Sub Group],Demand.[DemandGroupKey],Demand.[Demand Group]");
  for($DemInd=0;$DemInd -lt $Demands;$DemInd++)
  {
    $DemSubG=[math]::floor($DemInd/5);
    $DemG=[math]::floor($DemInd/10);
    $DemandFile.writeline($DemInd.ToString()+","+$DemInd+","+$DemSubG+","+"DemSubGrp-"+$DemSubG+","+$DemG+","+"DemGroup-"+$DemG);
  }
  $DemandFile.close();
}
function generateTransports
{
	param($Transports);
	$TransFile=[System.IO.StreamWriter]("$OutputDirectory\Dimension.Transport.csv")
	$TransFile.writeline("Transport.[TransportKey],Transport.[Transport],Transport.[TransportSubGroupKey],Transport.[Transport Sub Group],Transport.[TransportGroupKey],Transport.[Transport Group]");
  for($TranInd=0;$TranInd -lt $Transports;$TranInd++)
  {
    $TranSubG=[math]::floor($TranInd/5);
    $TranG=[math]::floor($TranInd/10);
    $TransFile.writeline($TranInd.ToString()+","+$TranInd+","+$TranSubG+","+"TranSubGrp-"+$TranSubG+","+$TranG+","+"TranGroup-"+$TranG);
  }
  $TransFile.close();
}
function generateCustomers
{
	param($Customers);
	$CustFile=[System.IO.StreamWriter]("$OutputDirectory\Dimension.Customer.csv")
	$CustFile.writeline("Customer.[CustomerKey],Customer.[Customer],Customer.[CustomerSubGroupKey],Customer.[Customer Sub Group],Customer.[CustomerGroupKey],Customer.[Customer Group]");
  for($CustInd=0;$CustInd -lt $Customers;$CustInd++)
  {
    $CustSubG=[math]::floor($CustInd/5);
    $CustG=[math]::floor($CustInd/10);
    $CustFile.writeline($CustInd.ToString()+","+$CustInd+","+$CustSubG+","+"CustSubGrp-"+$CustSubG+","+$CustG+","+"CustGroup-"+$CustG);
  }
  $CustFile.close();
}
function generateResources
{
	param($LocationsArray,$DomSuppliers,$IntlSuppliers,$Stores,$LDC1,$LDC2);
	$ResFile=[System.IO.StreamWriter]("$OutputDirectory\Dimension.Resource.csv");
	$ResFile.writeline("Resource.[ResourceKey],Resource.[Resource],Resource.[ResourceSubGroupKey],Resource.[Resource Sub Group],Resource.[ResourceGroupKey],Resource.[Resource Group]");
	
	###GenerateActivities Function Copy
	$ResInd=0;	
	$StartLDC1=0;
	
	## Suppliers to Level 1 DC Connection;
	for($LocInd=0;$LocInd -lt ($IntlSuppliers);$LocInd++)  
	{
	for($DCInd=0;$DCInd -lt $LDC1;$DCInd++){
	
	$Resource="Res-"+$LocationsArray[$LDC1+$LDC2+$Stores+$LocInd]+"-"+$LocationsArray[$Stores+$DCInd];
    $ResFile.writeline($ResInd.ToString()+","+$Resource+","+[math]::floor($ResInd/5)+",ResourceSubGroup-"+[math]::floor($ResInd/5)+","+[math]::floor($ResInd/10)+",ResourceGroup-"+[math]::floor($ResInd/10));
    $ResourceHash.Set_Item($ResInd,$Resource);
	$FindResKeyHash.Set_Item($Resource,$ResInd);
    $ResInd++;
	$Resource="Res-"+$LocationsArray[$Stores+$DCInd];
    $ResFile.writeline($ResInd.ToString()+","+$Resource+","+[math]::floor($ResInd/5)+",ResourceSubGroup-"+[math]::floor($ResInd/5)+","+[math]::floor($ResInd/10)+",ResourceGroup-"+[math]::floor($ResInd/10));
    $ResourceHash.Set_Item($ResInd,$Resource);
	$FindResKeyHash.Set_Item($Resource,$ResInd);
    $ResInd++;
	$Resource="Res-"+$LocationsArray[$Stores+$DCInd]+"-I";
    $ResFile.writeline($ResInd.ToString()+","+$Resource+","+[math]::floor($ResInd/5)+",ResourceSubGroup-"+[math]::floor($ResInd/5)+","+[math]::floor($ResInd/10)+",ResourceGroup-"+[math]::floor($ResInd/10));
    $ResourceHash.Set_Item($ResInd,$Resource);
	$FindResKeyHash.Set_Item($Resource,$ResInd);
    $ResInd++;
    }
	}
	
	##RDC  to Stores Connection...
	$StartStore=0;
	
	for($LocInd=0;$LocInd -lt $LDC2;$LocInd++)
	{
	  for($StoreInd=0;$StoreInd -lt 2*($Stores/$LDC2);$StoreInd++){
    $Resource="Res-"+$LocationsArray[$Stores+$LDC1+$LocInd]+"-"+($LocationsArray[($StartStore+$StoreInd)%$Stores]);
    $ResFile.writeline($ResInd.ToString()+","+$Resource+","+[math]::floor($ResInd/5)+",ResourceSubGroup-"+[math]::floor($ResInd/5)+","+[math]::floor($ResInd/10)+",ResourceGroup-"+[math]::floor($ResInd/10));
    $ResourceHash.Set_Item($ResInd,$Resource);
	$FindResKeyHash.Set_Item($Resource,$ResInd);
    $ResInd++;
    
    }
	$StartStore+=($Stores/$LDC2);
	}
	$StartStore=0;
	


	##Level 1 DC to Level 2 DC 
	$LeftLoc=($LDC2/2)%($LDC1/2);
	$LeftLoc=$LeftLoc/2;
	$AppendInd=$LeftLoc;
	$StartDc=0;
	$ind=0;
    for($LocInd=0;$LocInd -lt ($LDC1);$LocInd++)
    {
	  for($DCInd=0;$DCInd -lt [math]::floor($LDC2/$LDC1)+$AppendInd;$DCInd++){
    $Resource="Res-"+$LocationsArray[$Stores+$LocInd]+"-"+$LocationsArray[$Stores+$LDC1+$StartDc+$DCInd];
    $ResFile.writeline($ResInd.ToString()+","+$Resource+","+[math]::floor($ResInd/5)+",ResourceSubGroup-"+[math]::floor($ResInd/5)+","+[math]::floor($ResInd/10)+",ResourceGroup-"+[math]::floor($ResInd/10));
    $ResourceHash.Set_Item($ResInd,$Resource);
	$FindResKeyHash.Set_Item($Resource,$ResInd);
    $ResInd++;
	$Resource="Res-"+$LocationsArray[$Stores+$LocInd]+"-O";
    $ResFile.writeline($ResInd.ToString()+","+$Resource+","+[math]::floor($ResInd/5)+",ResourceSubGroup-"+[math]::floor($ResInd/5)+","+[math]::floor($ResInd/10)+",ResourceGroup-"+[math]::floor($ResInd/10));
    $ResourceHash.Set_Item($ResInd,$Resource);
	$FindResKeyHash.Set_Item($Resource,$ResInd);
    $ResInd++;
    }
	
	$StartDc=$StartDc+[math]::floor($LDC2/$LDC1)+$AppendInd;
	$LeftLoc=$LeftLoc-2;
	if($LeftLoc -lt 0)
	  {
	  $AppendInd=0;
	  }
	   if($LocInd -eq $LDC1/2-1)
	  {
	    $LeftLoc=($LDC2/2)%($LDC1/2);
	$LeftLoc=$LeftLoc/2;
	$AppendInd=$LeftLoc;
	$StartDc=0;
	$ind++;
	  }
    }
	
	$LeftLoc=($LDC2/2)%($LDC1/2);
	$LeftLoc=$LeftLoc/2;
	$AppendInd=$LeftLoc;
	$StartDc=0;
	
    for($LocInd=0;$LocInd -lt ($LDC1);$LocInd++)
    {
	  for($DCInd=0;$DCInd -lt [math]::floor($LDC2/$LDC1)+$AppendInd;$DCInd++){
    $Resource="Res-"+$LocationsArray[$Stores+$LocInd]+"-"+$LocationsArray[$Stores+$LDC1+($LDC2/2)+$StartDc+$DCInd];
	$ResFile.writeline($ResInd.ToString()+","+$Resource+","+[math]::floor($ResInd/5)+",ResourceSubGroup-"+[math]::floor($ResInd/5)+","+[math]::floor($ResInd/10)+",ResourceGroup-"+[math]::floor($ResInd/10));
    $ResourceHash.Set_Item($ResInd,$Resource);
	$FindResKeyHash.Set_Item($Resource,$ResInd);
    $ResInd++;
	
    }
	
	$StartDc=$StartDc+[math]::floor($LDC2/$LDC1)+$AppendInd;
	$LeftLoc=$LeftLoc-2;
	if($LeftLoc -lt 0)
	  {
	  $AppendInd=0;
	  }
	   if($LocInd -eq $LDC1/2-1)
	  {
	    $LeftLoc=($LDC2/2)%($LDC1/2);
	$LeftLoc=$LeftLoc/2;
	$AppendInd=$LeftLoc;
	$StartDc=0;
	$ind++;
	  }
    }
	###From LDC2 and to LDC2
	for($LocInd=0;$LocInd -lt $LDC2;$LocInd++)
	{
	  $Resource="Res-"+$LocationsArray[$Stores+$LDC1+$LocInd];
	  $ResFile.writeline($ResInd.ToString()+","+$Resource+","+[math]::floor($ResInd/5)+",ResourceSubGroup-"+[math]::floor($ResInd/5)+","+[math]::floor($ResInd/10)+",ResourceGroup-"+[math]::floor($ResInd/10));
    $ResourceHash.Set_Item($ResInd,$Resource);
	$FindResKeyHash.Set_Item($Resource,$ResInd);
    $ResInd++;
	$Resource="Res-"+$LocationsArray[$Stores+$LDC1+$LocInd]+"-I";
	  $ResFile.writeline($ResInd.ToString()+","+$Resource+","+[math]::floor($ResInd/5)+",ResourceSubGroup-"+[math]::floor($ResInd/5)+","+[math]::floor($ResInd/10)+",ResourceGroup-"+[math]::floor($ResInd/10));
    $ResourceHash.Set_Item($ResInd,$Resource);
	
	$FindResKeyHash.Set_Item($Resource,$ResInd);
    $ResInd++;
	}
	
	#Resources from Domestic Suppliers to RDC 
	for($LocInd=0;$LocInd -lt ($DomSuppliers);$LocInd++)  
	{
	for($DCInd=0;$DCInd -lt $LDC2;$DCInd++){
	
	$Resource="Res-"+$LocationsArray[$LDC1+$LDC2+$Stores+$IntlSuppliers+$LocInd]+"-"+$LocationsArray[$Stores+$LDC1+$DCInd];
    $ResFile.writeline($ResInd.ToString()+","+$Resource+","+[math]::floor($ResInd/5)+","+"ResourceSubGroup-"+[math]::floor($ResInd/5)+","+[math]::floor($ResInd/10)+","+"ActGroup-"+[math]::floor($ResInd/10));
    $ResourceHash.Set_Item($ResInd,$Activity);
	
	$FindResKeyHash.Set_Item($Resource,$ResInd);
    $ResInd++;
    }
	} 
	##Resources to Stores from the activities(LDC2-Stores)
	for($LocInd=0;$LocInd -lt $Stores;$LocInd++)
	{
	  $Resource="Res-"+$LocationsArray[$LocInd]+"-O";
	  $ResFile.writeline($ResInd.ToString()+","+$Resource+","+[math]::floor($ResInd/5)+",ResourceSubGroup-"+[math]::floor($ResInd/5)+","+[math]::floor($ResInd/10)+",ResourceGroup-"+[math]::floor($ResInd/10));
    $ResourceHash.Set_Item($ResInd,$Resource);
	
	$FindResKeyHash.Set_Item($Resource,$ResInd);
    $ResInd++;
	
	}
#>
	$ResFile.close();
}
function generateProduct
{
	param($ItemCount);
	$ProdFile=[System.IO.StreamWriter]("$OutputDirectory\Dimension.Product.csv");
	$ProdFile.writeline("Product.[ProductKey],Product.[Product],Product.[ProductSubGroupKey],Product.[Product Sub Group],Product.[ProductGroupKey],Product.[Product Group]");
	for($ItemInd=0;$ItemInd -lt $ItemCount;$ItemInd++)
	{
	 $ProdFile.writeline($ItemInd.ToString()+","+$ItemInd+","+[math]::floor($ItemInd/5)+",ItemSubGroup-"+[math]::floor($ItemInd/5)+","+[math]::floor($ItemInd/10)+",ItemGroup-"+[math]::floor($ItemInd/10));
	}
	$ProdFile.close();
  
}
function generateStorages
{
	param($Storages,$LocationsArray,$DCs,$Stores,$LDC1,$LDC2);
	$StoreFile=[System.IO.StreamWriter]("$OutputDirectory\Dimension.Storage.csv");
	$StoreFile.writeline("Storage.[StorageKey],Storage.[Storage],Storage.[StorageSubGroupKey],Storage.[Storage Sub Group],Storage.[StorageGroupKey],Storage.[Storage Group]");
    $StoreIndex=0;
  for($StoreInd=0;$StoreInd -lt ($LDC1/2);$StoreInd++)
  {
    $StoreSubG=[math]::floor($StoreIndex/5);
    $StoreG=[math]::floor($StoreIndex/10);
    $Storage="DC-"+$LocationsArray[$Stores+$StoreInd];
    $StoreFile.writeline($StoreIndex.ToString()+","+$Storage+","+$StoreSubG+","+"StoreSubGrp-"+$StoreSubG+","+$StoreG+","+"StoreGroup-"+$StoreG);
	$StoreIndex++;
  }
   for($StoreInd=0;$StoreInd -lt $LDC2;$StoreInd++)
  {
    $StoreSubG=[math]::floor($StoreIndex/5);
    $StoreG=[math]::floor($StoreIndex/10);
    $Storage="DC-"+$LocationsArray[$Stores+$LDC1+$StoreInd];
    $StoreFile.writeline($StoreIndex.ToString()+","+$Storage+","+$StoreSubG+","+"StoreSubGrp-"+$StoreSubG+","+$StoreG+","+"StoreGroup-"+$StoreG);
	$StoreIndex++;
  }
  $StoreFile.close();
}

function generateTime{

	param([DateTime]$StartDate,$Years);
	$QuarterHash=@{1="1";2="1";3="1";4="2";5="2";6="2";7="3";8="3";9="3";10="4";11="4";12="4"};
	[DateTime]$SDate=get-date $StartDate;
	[DateTime]$EndDate=$SDate.AddYears($Years);
	$TimeFile = [System.IO.StreamWriter] ("$OutputDirectory\Dimension.Time.csv");
	$TimeFile.writeline("Time.[FiscalYearKey],Time.[Fiscal Year],Time.[FiscalQuarterKey],Time.[Fiscal Quarter],Time.[FiscalMonthKey],Time.[Fiscal Month],Time.[FiscalWeekKey],Time.[Fiscal Week]");
	$WeekCount=0;
	$YearKey=$SDate;
	$MonthKey=$SDate;
	$QuarterKey=$SDate;
	$WeekKey=$SDate;
	write-host "SDate before Loop"+$SDate;
	while($SDate -lt $EndDate)
	{  
	   $WeekCount=$WeekCount+1;
	   $MonthName=get-date $SDate -format "M";
	   $MonthName=$MonthName.split(" ")[0];
       $WeekCnt=[math]::floor($WeekCount/7);
       if(!($PrevMonth) -or !($PrevMonth -eq $MonthName))
       {
         $MonthKey=get-date $SDate -format "yyyy-MM-dd";
         $PrevMonth=$MonthName;
       }
       if(!($PrevQ) -or !($PrevQ -eq $QuarterHash.Get_Item($SDate.Month)))
       {
         $QuarterKey=get-date $SDate -format "yyyy-MM-dd";
         $PrevQ=$QuarterHash.Get_Item($SDate.Month);
       }
        if(!($PrevYear) -or !($PrevYear -eq $SDate.Year))
       {
         $YearKey=get-date $SDate -format "yyyy-MM-dd";
         $PrevYear=$SDate.Year;
       }
       #write-host $SDate.Month;
       #write-host $QuarterHash.Get_Item($SDate.Month);
       $date=get-date $SDate -format "yyyy-MM-dd";
       $TimeFile.writeline($YearKey+",Y-"+$SDate.Year.ToString()+","+$QuarterKey+",Q-"+$QuarterHash.Get_Item($SDate.Month)+","+$MonthKey+","+$MonthName+","+$date+",W-"+$WeekCount);
       $SDate=$SDate.AddDays(7);
	} 
	$script:Weeks=$WeekCnt;
	$TimeFile.close();

}
function generateItems
{
	param($ItemCount);
	$ItemFile=[System.IO.StreamWriter]("$OutputDirectory\Dimension.Items.csv");
	$ItemFile.writeline("Item.[ItemKey],Item.[Item],Item.[ItemSubGroupKey],Item.[Item Sub Group],Item.[ItemGroupKey],Item.[Item Group]");
	for($ItemInd=0;$ItemInd -lt $ItemCount;$ItemInd++)
	{
	 $ItemFile.writeline($ItemInd.ToString()+","+$ItemInd+","+[math]::floor($ItemInd/5)+",ItemSubGroup-"+[math]::floor($ItemInd/5)+","+[math]::floor($ItemInd/10)+",ItemGroup-"+[math]::floor($ItemInd/10));
	}
	$ItemFile.close();
}
function generateLocations
{
  param($LocationsArray);
  $LocFile=[System.IO.StreamWriter] ("$OutputDirectory\Dimension.Locations.csv");
  $LocFile.writeline("Location.[LocationKey],Location.[Location],Location.[LocationSubGroupKey],Location.[Location Sub Group],Location.[LocationGroupKey],Location.[Location Group]");
  for($LocInd=0;$LocInd -lt $LocationsArray.Count;$LocInd++)
  {
   $LocGrp=[math]::floor($LocInd/10);
   $LocSubGrp=[math]::floor($LocInd/5);
   $LocationHash.Set_Item($LocationsArray[$LocInd],$LocInd);
   $LocFile.writeline($LocInd.ToString()+","+$LocationsArray[$LocInd]+","+$LocSubGrp+","+"LocSubGrp-"+$LocSubGrp+","+$LocGrp+",LocGrp-"+$LocGrp);
  }   
  $LocFile.close();

}
function convertListToString {
  param ($listvar);
  $liststring = "";
  $listcounter = 0;
  foreach ($listelem in $listvar) 
  {
    if ($listcounter -eq 0)
    {
      $liststring = -join ($listelem, "");
    }
    else
    {
      $liststring = -join ($liststring, ",", $listelem);
    }
    $listcounter = $listcounter + 1;
  }
  $liststring;
}
function toInteger {
  param ($numstring);
  try
  {
    [convert]::ToInt32(-join("", $numstring));
  }
  catch
  {
    write-host "Error converting '$numstring' to integer: $_.Exception.Message";
    0;
  }
} 
function toFloat {
  param ($numstring);
  try
  {
    [convert]::ToInt32(-join("", $numstring));
  }
  catch
  {
    write-host "Error converting '$numstring' to integer: $_.Exception.Message";
    0;
  }
}
function getParameter {
  param ($default, $paramname);
  if("true" -eq $usesettingsfile)
  {
    $content = get-childitem $settingsfile | get-content;
    $newcontent = -join ($content);
    $settings = $newcontent | select-xml "Settings/Setting[@id='$paramname']";
    if(!$settings)
    {
      write-host "$paramname not specified, defaults to: $default";
      $script:functionreturn = $default;
    }
    else
    {
      $settings = foreach ($setting in $settings) { -join ($setting, ""); };
      $settingstring = convertListToString $settinglist;
      write-host "$paramname specified by settings file: $settings";
      $script:functionreturn = $settings;
    }
  }
  else
  {
    write-host "$paramname not specified, defaults to: $default";
    $script:functionreturn = $default;
  }
}

function loadParameters {
  if(!$SettingsFile)
  {
    "No Settings file specified";
    $script:usesettingsfile = "false";
  }
  else
  {
    "Settings file specified as: $SettingsFile";
    $parent = split-path $SettingsFile -parent;



    if (!$parent)
    {
      $parent = get-location;
    }

    if (!(test-path $SettingsFile))
    {
      write-host "Warning: can't find settings file $SettingsFile" -ForegroundColor Yellow;
      $script:usesettingsfile = "false";
    }
    else
    {
      $script:usesettingsfile = "true";
    }
  }

  if (!$OutputDirectory)
  {
    $functionresult = getParameter "C:\Temp\psr-scs-data" "OutputDirectory";
    $functionresult;
    $script:OutputDirectory = $functionreturn;
  }
  else
  {
    write-host "OutputDirectory specified by command line: $OutputDirectory";
  }

  if (!(test-path $OutputDirectory))
  {
    new-item -type directory -path $OutputDirectory > null;
  }
  $script:OutputDirectory = -join ("", (resolve-path $OutputDirectory));

  

  if (!$ItemCount)
  {
    $functionresult = getParameter "100" "ItemCount";
    $functionresult;
    $script:ItemCount = toInteger $functionreturn;
  }
  else
  {
    write-host "ItemCount specified by command line: $ItemCount";
  }
   if (!$StartDate)
  {
    $functionresult = getParameter "100" "StartDate";
    $functionresult;
    $script:StartDate = [DateTime] $functionreturn;
  }
  else
  {
    write-host "StartDate specified by command line: $StartDate";
  }
if (!$Years)
  {
    $functionresult = getParameter "100" "Years";
    $functionresult;
    $script:Years = toInteger $functionreturn;
  }
  else
  {
    write-host "Years specified by command line: $Years";
  }
  if (!$Slices)
  {
    $functionresult = getParameter "100" "Slices";
    $functionresult;
    $script:Slices = toInteger $functionreturn;
  }
  else
  {
    write-host "Slices specified by command line: $Slices";
  }
  
     if (!$Customers)
  {
    $functionresult = getParameter "100" "Customers";
    $functionresult;
    $script:Customers = toInteger $functionreturn;
  }
  else
  {
    write-host "Customers specified by command line: $Customers";
  }
  if (!$Transports)
  {
    $functionresult = getParameter "100" "Transports";
    $functionresult;
    $script:Transports = toInteger $functionreturn;
  }
  else
  {
    write-host "Transports specified by command line: $Transports";
  }
   if (!$Demands)
  {
    $functionresult = getParameter "100" "Demands";
    $functionresult;
    $script:Demands = toInteger $functionreturn;
  }
  else
  {
    write-host "Demands specified by command line: $Demands";
  }
  if (!$Activities)
  {
    $functionresult = getParameter "100" "Activities";
    $functionresult;
    $script:Activities = toInteger $functionreturn;
  }
  else
  {
    write-host "Activities specified by command line: $Activities";
  }
    if (!$WithKey)
  {
    $functionresult = getParameter "100" "WithKeys";
    $functionresult;
    $script:WithKey = toInteger $functionreturn;
  }
  else
  {
    write-host "WithKey specified by command line: $WithKey";
  }
   if (!$Stores)
  {
    $functionresult = getParameter "100" "Stores";
    $functionresult;
    $script:Stores = toInteger $functionreturn;
  }
  else
  {
    write-host "Stores specified by command line: $Stores";
  }
  
  if (!$Suppliers)
  {
    $functionresult = getParameter "100" "Suppliers";
    $functionresult;
    $script:Suppliers = toInteger $functionreturn;
  }
  else
  {
    write-host "Suppliers specified by command line: $Suppliers";
  }
  if (!$LDC1)
  {
    $functionresult = getParameter "100" "LDC1";
    $functionresult;
    $script:LDC1 = toInteger $functionreturn;
  }
  else
  {
    write-host "LDC1 specified by command line: $LDC1";
  }
  if (!$LDC2)
  {
    $functionresult = getParameter "100" "LDC2";
    $functionresult;
    $script:LDC2 = toInteger $functionreturn;
  }
  else
  {
    write-host "LDC2 specified by command line: $LDC2";
  }
   if (!$SupCanSupply)
  {
    $functionresult = getParameter "2" "SupCanSupply";
    $functionresult;
    $script:SupCanSupply = toInteger $functionreturn;
  }
  else
  {
    write-host "SupCanSupply specified by command line: $SupCanSupply";
  }
  if (!$CommonItems)
  {
    $functionresult = getParameter "2" "CommonItems";
    $functionresult;
    $script:CommonItems = toInteger $functionreturn;
  }
  else
  {
    write-host "CommonItems specified by command line: $CommonItems";
  }
  if(!$IntlSuppliers)
  {
   $functionresult = getParameter "2" "IntlSuppliers";
    $functionresult;
    $script:IntlSuppliers = toInteger $functionreturn;
   
  }else{
        write-host "IntlSuppliers specified by command line: $IntlSuppliers";
  }
  if(!$DomSuppliers)
  {
   $functionresult = getParameter "2" "DomSuppliers";
    $functionresult;
    $script:DomSuppliers = toInteger $functionreturn;
   
  }else{
        write-host "IntlSuppliers specified by command line: $IntlSuppliers";
  }
  if(!$ItemRatio)
  {
   $functionresult = getParameter "0.75" "ItemRatio";
    $functionresult;
    $script:ItemRatio =  $functionreturn;
   
  }else{
        write-host "ItemRatio specified by command line: $ItemRatio";
  }
  
}

generateDataMain;