<#

The MIT License (MIT)

Copyright (c) 2016 Michał Borejszo

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

#>

param (
    [Parameter()]
    [int]$speed = 3,
    [switch]$nosound
)

<#########################################
##########################################
##########################################

This is heavily based on code taken from: http://poshcode.org/2898

##########################################
##########################################
##########################################>
$global:BoxChars = new-object PSObject -Property @{
   'HorizontalDouble'            = ([char]9552).ToString()
   'VerticalDouble'              = ([char]9553).ToString()
   'TopLeftDouble'               = ([char]9556).ToString()
   'TopRightDouble'              = ([char]9559).ToString()
   'BottomLeftDouble'            = ([char]9562).ToString()
   'BottomRightDouble'           = ([char]9565).ToString()
   'HorizontalDoubleSingleDown'  = ([char]9572).ToString()
   'HorizontalDoubleSingleUp'    = ([char]9575).ToString()
   'Horizontal'                  = ([char]9472).ToString()
   'Vertical'                    = ([char]9474).ToString()
   'TopLeft'                     = ([char]9484).ToString()
   'TopRight'                    = ([char]9488).ToString()
   'BottomLeft'                  = ([char]9492).ToString()
   'BottomRight'                 = ([char]9496).ToString()
   'Cross'                       = ([char]9532).ToString()
   'VerticalDoubleRightSingle'   = ([char]9567).ToString()
   'VerticalDoubleLeftSingle'    = ([char]9570).ToString()
   'FullBlock'                   = ([char]9608).ToString()
   'DoubleDownAndHorizontal'     = ([char]9574).ToString()
   'DoubleUpAndHorizontal'       = ([char]9577).ToString()
}
$global:RectType = "system.management.automation.host.rectangle"
 
function Reset-Buffer {
param(
   $Position = $Host.UI.RawUI.WindowPosition,
   [int]$Height = $Host.UI.RawUI.WindowSize.Height,
   [int]$Width = $Host.UI.RawUI.WindowSize.Width,
   # Note: all edges are padded by 1 for the box edges, but we also pad each side by this ammount:
   [int]$Padding = 1,
   $ForegroundColor = $Host.UI.RawUI.ForegroundColor,
   $BackgroundColor = $Host.UI.RawUI.BackgroundColor,
   $BorderColor     = "Yellow",
   [switch]$NoBorder,
   [switch]$ShowInput,
   [string]$Title = ""
)
 
$global:BufferHeight          = $Height
$global:BufferWidth           = $Width
$global:BufferPadding         = $Padding
$global:BufferForegroundColor = $ForegroundColor
$global:BufferBackgroundColor = $BackgroundColor
$global:BufferBorderColor     = $BorderColor    
 
   if($NoBorder) {
      $global:BufferBoxSides = 0
   } else {
      $global:BufferBoxSides = 2
   }
   if($ShowInput) {
      $global:BufferHeight -= 2
   }
 
   $Host.UI.RawUI.SetBufferContents($Position,(New-BufferBox $BufferHeight $BufferWidth -Title:$Title -NoBorder:$NoBorder -ShowInput:$ShowInput -Background $BufferBackgroundColor -Border $BufferBorderColor))
 
   
   $global:BufferPosition = $Position  
   $global:BufferPosition.X += $global:BufferPadding + ($global:BufferBoxSides/2)
   # this gets set to the BOTTOM line, because I assume text will flow in from the bottom.
   $global:BufferPosition.Y += $global:BufferHeight - 2
   # and this goes below that ...
   $global:BufferPromptPosition = $BufferPosition
   $global:BufferPromptPosition.Y += 2
   $global:BufferPromptPosition.X += 2 - $global:BufferPadding # Prompt = "> "
}
 
function New-BufferBox {
param(
   [int]$Height = $global:BufferHeight,
   [int]$Width = $global:BufferWidth,
   $Title = "",
   [switch]$NoBorder,
   [switch]$ShowInput,
   $BackgroundColor = $global:BufferBackgroundColor,
   $BorderColor = $global:BufferBorderColor
)
   $Width = $Width - $global:BufferBoxSides
   
   $LineTop =( $global:BoxChars.HorizontalDouble * 2) + $Title `
            + $($global:BoxChars.HorizontalDouble * ($Width - ($Title.Length+2)))
   
   $LineField = ' ' * $Width
   $LineBottom = $global:BoxChars.HorizontalDouble * $Width
   $LineSeparator = $global:BoxChars.Horizontal * $Width
   $LinePrompt = '> ' + ' ' * ($Width-2) # Prompt = "> "
   
   if(!$NoBorder) {
      $LineField = $global:BoxChars.VerticalDouble + $LineField + $global:BoxChars.VerticalDouble
      $LinePrompt = $global:BoxChars.VerticalDouble + $LinePrompt + $global:BoxChars.VerticalDouble
      $LineBottom = $global:BoxChars.BottomLeftDouble + $LineBottom + $global:BoxChars.BottomRightDouble
      $LineTop = $global:BoxChars.TopLeftDouble + $LineTop + $global:BoxChars.TopRightDouble
      $LineSeparator = $global:BoxChars.VerticalDoubleRightSingle + $LineSeparator + $global:BoxChars.VerticalDoubleLeftSingle
   }
 
   if($ShowInput) {
      $box = &{$LineTop;1..($Height - 2) |% {$LineField};$LineSeparator;$LinePrompt;$LineBottom}
   } else {
      $box = &{$LineTop;1..($Height - 2) |% {$LineField};$LineBottom}
   }
   $boxBuffer = $Host.UI.RawUI.NewBufferCellArray($box,$BorderColor,$BackgroundColor)
   return ,$boxBuffer
}
 
function Move-Buffer {
param(
   $Position = $global:BufferPosition,
   [int]$Left = $($global:BufferBoxSides/2),
   [int]$Top = (2 - $global:BufferHeight),
   [int]$Width = $global:BufferWidth - $global:BufferBoxSides,
   [int]$Height = $global:BufferHeight,
   [int]$Offset = -1
)
   $Position.X += $Left
   $Position.Y += $Top
   $Rect = New-Object $RectType $Position.X, $Position.Y, ($Position.X + $width), ($Position.Y + $height -1)
   $Position.Y += $OffSet
   $Host.UI.RawUI.ScrollBufferContents($Rect, $Position, $Rect, (new-object System.Management.Automation.Host.BufferCell(' ',$global:BufferForegroundColor,$global:BufferBackgroundColor,'complete')))
}
 
function Out-Buffer {
param(
   [Parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
   $Message,
   [Parameter(ValueFromPipelineByPropertyName=$true)]
   $ForegroundColor = $global:BufferForegroundColor,
   [Parameter(ValueFromPipelineByPropertyName=$true)]
   $BackgroundColor = $global:BufferBackgroundColor,
   
   [switch]$NoScroll,
   
   [Parameter(ValueFromPipelineByPropertyName=$true)]
   $Position = $global:BufferPosition,
   [Parameter(ValueFromPipelineByPropertyName=$true)]
   [int]$Left = 0,
   [Parameter(ValueFromPipelineByPropertyName=$true)]
   [int]$Top    = $(3 - $global:BufferHeight),  # Box Edge + New Lines
   [Parameter(ValueFromPipelineByPropertyName=$true)]
   [int]$Width  = ($global:BufferWidth - $global:BufferBoxSides), # Box Edge
   [Parameter(ValueFromPipelineByPropertyName=$true)]
   [int]$Height = ($global:BufferHeight - $global:BufferBoxSides), # Box Edge
   [Parameter(ValueFromPipelineByPropertyName=$true)]
   [int]$Offset = $( 0 - ($Message.Split("`n").Count))
)
process {
   $lineCount = $Message.Split("`n").Count
 
   #$Width = $Width - ($global:BufferPadding * 2)
   $Width = $Message.Length
   if(!$NoScroll){ Move-Buffer $Position $Left $Top $Width $Height $Offset }
   
   $MessageBuffer = New-Object "System.Management.Automation.Host.BufferCell[,]" $lineCount, $width
   
   $index = 0
   foreach( $line in $Message.Split("`n") ) {
      $Buffer = $Host.UI.RawUI.NewBufferCellArray( @($line.Trim("`r").PadRight($Width)), $ForegroundColor, $BackgroundColor )
      for($i = 0; $i -lt $width; $i++) {
         $MessageBuffer[$index,$i] = $Buffer[0,$i]
      }
      $index++
   }
   
   $Y = $global:BufferPosition.Y
   $global:BufferPosition.Y -= $lineCount - 1
   $Host.UI.RawUI.SetBufferContents($global:BufferPosition,$MessageBuffer)
   $global:BufferPosition.Y = $Y
}
}
 
function Set-BufferInputLine {
param([String]$Line = "")
   $PromptText = $line.PadRight(($global:BufferWidth - $line.Length - 3)) # Prompt = "> "
   
   $CursorPosition = $BufferPromptPosition
   $CursorPosition.X += $line.Length
   
   $Prompt = $Host.UI.RawUI.NewBufferCellArray( @($PromptText),$global:BufferForegroundColor, $global:BufferBackgroundColor)
   $Host.UI.RawUI.SetBufferContents( $BufferPromptPosition, $prompt )
   $Host.UI.RawUI.CursorPosition = $CursorPosition
}

<#########################################
##########################################
##########################################

End code from: http://poshcode.org/2898

##########################################
##########################################
##########################################>

$version = "0.2"

$board_x = 40
$board_y = 40
$sideboard_width = 15

$direction_up = 0
$direction_left = 1
$direction_down = 2
$direction_right = 3

function Get-Vector-Distance
{
    $dist = [System.Math]::Sqrt([System.Math]::Pow(($args[0].x - $args[1].x), 2) + [System.Math]::Pow(($args[0].y - $args[1].y), 2))
    Write-Output $dist
}

# returns the vector of current movement direction
function Get-Direction
{
    $dir = new-object PSObject -Property @{
        'X' = 0
        'Y' = 0
    }
    if ($global:direction -eq $direction_up)
    { 
        $dir.y = -1
        $dir.x = 0
    }
    elseif ($global:direction -eq $direction_left)
    { 
        $dir.y = 0
        $dir.x = -1
    }
    elseif ($global:direction -eq $direction_down)
    { 
        $dir.y = 1
        $dir.x = 0
    }
    elseif ($global:direction -eq $direction_right)
    { 
        $dir.y = 0
        $dir.x = 1
    }
    
    Write-Output $dir
}

function Reset-Buffer-Snake
{
    Reset-Buffer $Position $board_y ($board_x + $sideboard_width) 1 -ForegroundColor 'Gray' -BackgroundColor 'Black' -BorderColor 'Green' -Title PowerSnake
}

function Reset-Game
{
    $global:score = 0
    $global:snake = @(
        (new-object PSObject -Property @{
            'X' = ($board_x / 2)
            'Y' = ($board_y / 2)
        }),
        (new-object PSObject -Property @{
            'X' = ($board_x / 2)
            'Y' = ($board_y / 2) + 1
        }),
        (new-object PSObject -Property @{
            'X' = ($board_x / 2)
            'Y' = ($board_y / 2) + 2
        })
    )
    $global:food = new-object PSObject -Property @{
        'X' = 0
        'Y' = 0
    }
    $global:direction = $direction_up
    Reset-Buffer-Snake
    Draw-Board
}

function Draw-Board
{
    #top
    $global:BufferPosition.x = ($board_x - 1)
    $global:BufferPosition.y = 0
    Out-Buffer $global:BoxChars.DoubleDownAndHorizontal 'green' 'black' -NoScroll
    
    #bottom
    $global:BufferPosition.x = ($board_x - 1)
    $global:BufferPosition.y = ($board_y - 1)
    Out-Buffer $global:BoxChars.DoubleUpAndHorizontal 'green' 'black' -NoScroll

    #middle
    for($n=1; $n -lt ($board_y - 1); $n++)
    {
        $global:BufferPosition.x = ($board_x - 1)
        $global:BufferPosition.y = $n
        Out-Buffer $global:BoxChars.VerticalDouble 'green' 'black' -NoScroll
    }

    #instructions
    $global:BufferPosition.x = $board_x
    $global:BufferPosition.y = ($board_y - 5)
    Out-Buffer "Use arrows" 'gray' 'black' -NoScroll
    $global:BufferPosition.x = $board_x
    $global:BufferPosition.y = ($board_y - 4)
    Out-Buffer "to steer." 'gray' 'black' -NoScroll
    $global:BufferPosition.x = $board_x
    $global:BufferPosition.y = ($board_y - 2)
    Out-Buffer "ESC - exit" 'gray' 'black' -NoScroll

    #Score
    $global:BufferPosition.x = $board_x
    $global:BufferPosition.y = 1
    Out-Buffer "Score:" 'white' 'black' -NoScroll
    Draw-Score

    #Speed
    $global:BufferPosition.x = $board_x
    $global:BufferPosition.y = 3
    Out-Buffer ("Speed: " + $speed) 'white' 'black' -NoScroll
}

function Draw-Score
{
    $global:BufferPosition.x = ($board_x + 7)
    $global:BufferPosition.y = 1
    Out-Buffer $global:score.ToString() 'white' 'black' -NoScroll
}

function Game-Over
{
    $global:BufferPosition.x = ($board_x / 2)
    $global:BufferPosition.y = ($board_y / 2)
    Out-Buffer "GAME OVER" 'White' 'black' -NoScroll
    $global:BufferPosition.x = ($board_x / 2)
    $global:BufferPosition.y = (($board_y / 2) + 2)
    Out-Buffer "Press any key to restart." 'White' 'black' -NoScroll

    if(!$nosound) { [console]::Beep(500, 500) }

    [System.Console]::ReadKey($true)
}

switch ($speed)
{
    1 { $speed_ = 500; break }
    2 { $speed_ = 250; break }
    3 { $speed_ = 100; break }
    4 { $speed_ = 50; break }
    5 { $speed_ = 25; break }
    default { $speed_ = 100; $speed = 3; break }
}

$pshost = Get-Host              # Get the PowerShell Host.
$pswindow = $pshost.UI.RawUI    # Get the PowerShell Host's UI.
$org_buffsize = $pswindow.BufferSize
$org_windowsize = $pswindow.windowsize
try
{
    cls
    [console]::CursorVisible=$false

    <#$newsize = $pswindow.BufferSize # Get the UI's current Buffer Size.
    #$newsize.width = $board_x 
    #$newsize.Height = 20
    $pswindow.buffersize = $newsize # Set the new Buffer Size as active.#>

    $newsize = $pswindow.windowsize # Get the UI's current Window Size.
    $newsize.width = ($board_x + $sideboard_width)
    $newsize.Height = $board_y
    $pswindow.windowsize = $newsize # Set the new Window Size as active.

    $Position = $Host.UI.RawUI.WindowPosition
    $Position.X += 0
    $Position.Y += 0

    Reset-Buffer-Snake

    # Display info
    $global:BufferPosition.x = ($board_x / 2)
    $global:BufferPosition.y = ($board_y / 2)
    Out-Buffer ("PowerSnake " + $version) 'White' 'black' -NoScroll
    $global:BufferPosition.x = ($board_x / 2)
    $global:BufferPosition.y = (($board_y / 2) + 1)
    Out-Buffer "Author: michal@traal.eu" 'White' 'black' -NoScroll
    $global:BufferPosition.x = ($board_x / 2)
    $global:BufferPosition.y = (($board_y / 2) + 3)
    Out-Buffer "Press any key to start." 'White' 'black' -NoScroll

    [System.Console]::ReadKey($true)
    Reset-Game

    # draw initial snake
    foreach($s in $global:snake)
    {
        $global:BufferPosition.x = $s.X
        $global:BufferPosition.y = $s.y
        Out-Buffer $global:BoxChars.FullBlock 'red' 'red' -NoScroll
    }

    # Gameloop
    $continue = 1
    while ($continue) {
    
        if ([Console]::KeyAvailable)
        {
            $key = [System.Console]::ReadKey($true)
            switch ($key.Key)
            {
                Escape { $continue = 0; break }
                LeftArrow { if($global:direction -ne $direction_right) {$global:direction = $direction_left}; break }
                RightArrow { if($global:direction -ne $direction_left) {$global:direction = $direction_right}; break }
                UpArrow { if($global:direction -ne $direction_down) {$global:direction = $direction_up}; break }
                DownArrow { if($global:direction -ne $direction_up) {$global:direction = $direction_down}; break }
            }
        }
        
        # do we have food on board?
        if ($global:food.X -eq 0 -and $global:food.Y -eq 0)
        {
            #place new food
            $newfood = new-object PSObject -Property @{
                'X' = 0
                'Y' = 0
            }
            while(1)
            {
                $newfood.X = Get-Random -Minimum 1 -Maximum ($board_x - 1)
                $newfood.Y = Get-Random -Minimum 1 -Maximum ($board_y - 1)
                $distance = Get-Vector-Distance $newfood $global:snake[0]
                if ($distance -lt 5) {continue}
                $ok = [bool]$true
                foreach($s in $snake)
                {
                    if ($s.x -eq $newfood.x -and $s.y -eq $newfood.y)
                    {
                        $ok = [bool]$false
                        break
                    }
                }
                if ($ok)
                {
                    $global:food = $newfood
                    $global:BufferPosition.x = $newfood.X
                    $global:BufferPosition.y = $newfood.Y
                    Out-Buffer $global:BoxChars.FullBlock 'blue' 'blue' -NoScroll
                    break
                }
            }
        }
        else
        {
            #redraw food
            $global:BufferPosition.x = $global:food.X
            $global:BufferPosition.y = $global:food.Y
            Out-Buffer $global:BoxChars.FullBlock 'blue' 'blue' -NoScroll
        }

        # get current movement vector
        $movement = Get-Direction 

        #find new head
        $newhead = new-object PSObject -Property @{
            'X' = $global:snake[0].X + $movement.x
            'Y' = $global:snake[0].Y + $movement.y
        }
        $newsnake = @($newhead)

        #check for collisions with board borders
        if ($newhead.x -eq 0 -or $newhead.y -eq 0 -or $newhead.x -eq ($board_x - 1) -or $newhead.y -eq ($board_y - 1))
        {
            Game-Over
            Reset-Game
            continue
        }

        $col = [bool]$false
        #check for collisions with snake
        foreach ($s in $snake)
        {
            if ($s.x -eq $newhead.x -and $s.y -eq $newhead.y)
            {
                $col = [bool]$true
            }
        }
        if ($col)
        {
            Game-Over
            Reset-Game
            continue
        }

        $gotfood = [bool]$false
        #check for food
        if ($newhead.x -eq $global:food.x -and $newhead.y -eq $global:food.y)
        {
            $gotfood = [bool]$true
        }

        if (!$gotfood)
        {
            #erase last snake "bit"
            $global:BufferPosition.x = $global:snake[-1].X
            $global:BufferPosition.y = $global:snake[-1].Y
            Out-Buffer $global:BoxChars.FullBlock 'black' 'black' -NoScroll

            #remove last element from array
            $global:snake = $global:snake[0..($global:snake.Length - 2)]
        }
        else
        { # food eaten
            #increment score
            $global:score++
            Draw-Score

            # reset food position, so new one is generated on next pass
            $global:food.x = 0
            $global:food.y = 0
        }
        
        # move the snake array
        foreach($s in $global:snake)
        {
            $newsnake += $s
        }
        $global:snake = $newsnake

        # draw snake on late "head"
        $global:BufferPosition.x = $global:snake[1].X
        $global:BufferPosition.y = $global:snake[1].y
        Out-Buffer $global:BoxChars.FullBlock 'red' 'red' -NoScroll

        # draw new "head"
        $global:BufferPosition.x = ($global:snake[0].X)
        $global:BufferPosition.y = ($global:snake[0].Y)
        Out-Buffer $global:BoxChars.FullBlock 'green' 'green' -NoScroll

        sleep -Milliseconds $speed_
    }
}
finally
{
    cls
    [console]::CursorVisible=$true
    #$pswindow.buffersize = $org_buffsize
    $pswindow.windowsize = $org_windowsize
}