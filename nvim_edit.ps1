param([string]$File, [int]$Line = 0)
$socket = $env:NVIM
if ($socket) {
    if ($Line -gt 0) {
        & nvim --server $socket --remote-tab "+$Line" $File
    } else {
        & nvim --server $socket --remote-tab $File
    }
} else {
    & nvim $File
}
