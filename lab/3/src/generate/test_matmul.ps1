$len_bit = @(1,2,3,4)
$len_int=@('2','4','8','16')
$1=$args[0]
if ($1 -eq $null) {
    $1=[int]0;
}
else {
    $1=[int]$1;
}


echo $1
cd generate_inst
(Get-Content -path "MatMul_t.S") -replace "qwq",$len_bit[$1]  | Set-Content -Path "MatMul.S"
python asm2verilogrom.py MatMul.S ..\..\pipeline_cpu\pipeline_cpu.srcs\sources_1\imports\CacheSrcCode\InstructionCache.v
cd ..\generate_data
python generate_mem_for_matmul.py $len_int[$1] > ..\..\pipeline_cpu\pipeline_cpu.srcs\sources_1\imports\CacheSrcCode\mem.sv
cd ..