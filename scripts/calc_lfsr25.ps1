$Width = 25
$Mask = [uint32]((1 -shl $Width) - 1)
$Step = 1 -shl 23

function Get-LfsrNext {
    param([uint32]$State)

    [uint32]$feedback = (($State -shr 24) -bxor ($State -shr 21)) -band 1
    return [uint32]((($State -shl 1) -band $Mask) -bor $feedback)
}

function Invoke-LinearTransform {
    param(
        [uint32[]]$Transform,
        [uint32]$State
    )

    [uint32]$result = 0
    $bit = 0
    while ($State -ne 0) {
        if (($State -band 1) -ne 0) {
            $result = $result -bxor $Transform[$bit]
        }
        $State = $State -shr 1
        $bit++
    }
    return $result
}

function Invoke-LfsrJump {
    param(
        [uint32]$State,
        [uint64]$Clocks
    )

    [uint32[]]$transform = 0..($Width - 1) | ForEach-Object {
        Get-LfsrNext ([uint32](1 -shl $_))
    }

    while ($Clocks -ne 0) {
        if (($Clocks -band 1) -ne 0) {
            $State = Invoke-LinearTransform $transform $State
        }

        [uint32[]]$squared = foreach ($value in $transform) {
            Invoke-LinearTransform $transform $value
        }
        $transform = $squared
        $Clocks = $Clocks -shr 1
    }
    return $State
}

[uint32]$seed = 1
[uint64]$period = (1 -shl $Width) - 1

"period = {0:N0}" -f $period
foreach ($multiple in 1..6) {
    [uint64]$clocks = $multiple * $Step
    [uint32]$state = Invoke-LfsrJump $seed $clocks
    $binary = [Convert]::ToString($state, 2).PadLeft($Width, '0')
    "{0} * 2^23 clocks = {1:N0}: decimal={2}, hex=0x{2:X7}, binary={3}" -f `
        $multiple, $clocks, $state, $binary
}

if ((Invoke-LfsrJump $seed $period) -ne $seed) {
    throw "Period verification failed"
}
