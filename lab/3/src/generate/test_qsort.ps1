$len_int = @(16,256,512,1024)
$len_hex=@('0x10','0x100','0x200','0x400')
$sp=@('0x00001','0x00001','0x00002','0x00004')
$1=$args[0]
if ($1 -eq $null) {
    $1=[int]0;
}
else {
    $1=[int]$1;
}
echo $1
cd generate_inst
((Get-Content -path "QuickSort_t.S") -replace "len",$len_hex[$1] ) -replace "sp_addr", $sp[$1] | Set-Content -Path "QuickSort.S"
python asm2verilogrom.py QuickSort.S ..\..\pipeline_cpu\pipeline_cpu.srcs\sources_1\imports\CacheSrcCode\InstructionCache.v
cd ..\generate_data
python generate_mem_for_quicksort.py $len_int[$1] > ..\..\pipeline_cpu\pipeline_cpu.srcs\sources_1\imports\CacheSrcCode\mem.sv
cd ..

#((Get-Content -path "cache_param_t.v") -replace "len",$len_hex[$1] ) -replace "sp_addr", $sp[$1] | Set-Content -Path "..\lab3.srcs\sources_1\imports\SourceCode\cache_param.v"