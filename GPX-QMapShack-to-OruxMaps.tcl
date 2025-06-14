# Convert QMapShack tracks to OruxMaps tracks
# ===========================================

# Important:
# - At least Java version 17 is required!

# Notes:
# - Additional user settings file is mandatory!
#   Name of file = this script's full path
#   where file extension "tcl" is replaced by "ini"
# - At least one additional localized resource file is mandatory!
#   Name of file = this script's full path
#   where file extension "tcl" is replaced by
#   2 lowercase letters ISO 639-1 code, e.g. "en"

# Force file encoding "utf-8"
# Usually required for Tcl/Tk version < 9.0 on Windows!

if {[encoding system] != "utf-8"} {
   encoding system utf-8
   exit [source $argv0]
}

if {![info exists tk_version]} {package require Tk}
wm withdraw .

set version "2025-06-14"
set script [file normalize [info script]]
set title [file tail $script]
set cwd [pwd]

# Required packages

foreach item {Thread msgcat tooltip} {
  if {[catch "package require $item"]} {
    ::tk::MessageBox -title $title -icon error \
	-message "Could not load required Tcl package '$item'" \
	-detail "Please install missing $tcl_platform(os) package!"
    exit
  }
}

# Procedure aliases

interp alias {} ::send {} ::thread::send
interp alias {} ::mc {} ::msgcat::mc
interp alias {} ::messagebox {} ::tk::MessageBox
interp alias {} ::tooltip {} ::tooltip::tooltip
interp alias {} ::style {} ::ttk::style
interp alias {} ::button {} ::ttk::button
interp alias {} ::checkbutton {} ::ttk::checkbutton
interp alias {} ::combobox {} ::ttk::combobox
interp alias {} ::radiobutton {} ::ttk::radiobutton
interp alias {} ::scrollbar {} ::ttk::scrollbar

# Define color palette

foreach {item value} {
Background #f0f0f0
ButtonHighlight #ffffff
Border #a0a0a0
ButtonText #000000
DisabledText #6d6d6d
Focus #e0e0e0
Highlight #0078d7
HighlightText #ffffff
InfoBackground #ffffe1
InfoText #000000
Trough #c8c8c8
Window #ffffff
WindowFrame #646464
WindowText #000000
} {set color$item $value}

# Global widget options

foreach {item value} {
background Background
foreground ButtonText
activeBackground Background
activeForeground ButtonText
disabledBackground Background
disabledForeground DisabledText
highlightBackground Background
highlightColor WindowFrame
readonlyBackground Background
selectBackground Highlight
selectForeground HighlightText
selectColor Window
troughColor Trough
Entry.background Window
Entry.foreground WindowText
Entry.insertBackground WindowText
Entry.highlightColor WindowFrame
Listbox.background Window
Listbox.highlightColor WindowFrame
Tooltip*Label.background InfoBackground
Tooltip*Label.foreground InfoText
} {option add *$item [set color$value]}

set dialog.wrapLength [expr [winfo screenwidth .]/2]
foreach {item value} {
Dialog.msg.wrapLength ${dialog.wrapLength}
Dialog.dtl.wrapLength ${dialog.wrapLength}
Dialog.msg.font TkDefaultFont
Dialog.dtl.font TkDefaultFont
Entry.highlightThickness 1
Label.borderWidth 1
Label.padX 0
Label.padY 0
Labelframe.borderWidth 0
Scale.highlightThickness 1
Scale.showValue 0
Scale.takeFocus 1
Tooltip*Label.padX 2
Tooltip*Label.padY 2
} {eval option add *$item $value}

# Global ttk widget options

style theme use clam

if {$tcl_version > 8.6} {
  if {$tcl_platform(os) == "Windows NT"} \
	{lassign {23 41 101 69 120} ry ul ll cy ht}
  if {$tcl_platform(os) == "Linux"} \
	{lassign { 3 21  81 49 100} ry ul ll cy ht}
  set CheckOff "
	<rect width='94' height='94' x='3' y='$ry'
	style='fill:white;stroke-width:3;stroke:black'/>
	"
  set CheckOn "
	<rect width='94' height='94' x='3' y='$ry'
	style='fill:white;stroke-width:3;stroke:black'/>
	<path d='M20 $ll L80 $ul M20 $ul L80 $ll'
	style='fill:none;stroke:black;stroke-width:14;stroke-linecap:round'/>
	"
  set RadioOff "
	<circle cx='49' cy='$cy' r='47'
	fill='white' stroke='black' stroke-width='3'/>
	"
  set RadioOn "
	<circle cx='49' cy='$cy' r='37'
	fill='black' stroke='white' stroke-width='20'/>
	<circle cx='49' cy='$cy' r='47'
	fill='none' stroke='black' stroke-width='3'/>
	"
  foreach item {CheckOff CheckOn RadioOff RadioOn} \
    {image create photo $item \
	-data "<svg width='125' height='$ht'>[set $item]</svg>"}

  foreach item {Check Radio} {
    style element create ${item}button.sindicator image \
	[list ${item}Off selected ${item}On]
    style layout T${item}button \
	[regsub indicator [style layout T${item}button] sindicator]
  }
}

if {$tcl_platform(os) == "Windows NT"}	{lassign {1 1} yb yc}
if {$tcl_platform(os) == "Linux"}	{lassign {0 2} yb yc}
foreach {item option value} {
. background $colorBackground
. bordercolor $colorBorder
. focuscolor $colorFocus
. darkcolor $colorWindowFrame
. lightcolor $colorWindow
. troughcolor $colorTrough
. selectbackground $colorHighlight
. selectforeground $colorHighlightText
TButton borderwidth 2
TButton padding "{0 -2 0 $yb}"
TCombobox arrowsize 15
TCombobox padding 0
TCheckbutton padding "{0 $yc}"
TRadiobutton padding "{0 $yc}"
} {eval style configure $item -$option [eval set . \"$value\"]}

foreach {item option value} {
TButton darkcolor {pressed $colorWindow}
TButton lightcolor {pressed $colorWindowFrame}
TButton background {focus $colorFocus pressed $colorFocus}
TCombobox background {focus $colorFocus pressed $colorFocus}
TCombobox bordercolor {focus $colorWindowFrame}
TCombobox selectbackground {!focus $colorWindow}
TCombobox selectforeground {!focus $colorWindowText}
TCheckbutton background {focus $colorFocus}
TRadiobutton background {focus $colorFocus}
Arrow.TButton bordercolor {focus $colorWindowFrame}
} {style map $item -$option [eval list {*}$value]}

# Global widget bindings

foreach item {TButton TCheckbutton TRadiobutton} \
	{bind $item <Return> {%W invoke}}
bind TCombobox <Return> {event generate %W <Button-1>}

bind Entry <FocusIn> {grab %W}
bind Entry <Tab> {grab release %W}
bind Entry <Button-1> {+button-1-press %W %X %Y}

proc scale_updown {w d} {$w set [expr [$w get]+$d*[$w cget -resolution]]}
bind Scale <MouseWheel> {scale_updown %W [expr %D>0?+1:-1]}
bind Scale <Button-4> {scale_updown %W -1}
bind Scale <Button-5> {scale_updown %W +1}
bind Scale <Button-1> {+focus %W}

proc button-1-press {W X Y} {
  set w [winfo containing $X $Y]
  if {"$w" == "$W"} {focus $W; return}
  grab release $W
  if {"$w" == ""} return
  focus $w
  switch [winfo class $w] {
    TCheckbutton -
    TRadiobutton -
    TButton	{$w instate !disabled {$w invoke}}
    TCombobox	{$w instate !disabled {ttk::combobox::Press "" $w \
		[expr $X-[winfo rootx $w]] [expr $Y-[winfo rooty $w]]}}
  }
}

# Bitmap arrow down

image create bitmap ArrowDown -data {
  #define x_width 9
  #define x_height 7
  static char x_bits[] = {
  0x00,0xfe,0x00,0xfe,0xff,0xff,0xfe,0xfe,0x7c,0xfe,0x38,0xfe,0x10,0xfe
  };
}

# Try using system locale for script
# If corresponding localized file does not exist, try locale "en" (English)
# Localized filename = script's filename where file extension "tcl"
# is replaced by 2 lowercase letters ISO 639-1 code

set locale [regsub {(.*)[-_]+(.*)} [::msgcat::mclocale] {\1}]
if {$locale == "c"} {set locale en}
#set locale en

set prefix [file rootname $script]

set list [list $locale en]
foreach item [glob -nocomplain -tails -path $prefix. -type f ??] \
	{lappend list [lindex [split $item .] end]}

unset locale
foreach item $list {
  set file $prefix.$item
  if {![file exists $file]} continue
  if {[catch {source $file} result]} {
    messagebox -title $title -icon error \
	-message "Error reading locale file '[file tail $file]':\n$result"
    exit
  }
  set locale $item
  ::msgcat::mclocale $locale
  break
}
if {![info exists locale]} {
  messagebox -title $title -icon error \
	-message "No locale file '[file tail $file]' found"
  exit
}

# Read user settings from file
# Filename = script's filename where file extension "tcl" is replaced by "ini"

set file [file rootname $script].ini
if {![file exist $file]} {
  messagebox -title $title -icon error \
	-message "[mc i01 [file tail $file]]"
  exit
} elseif {[catch {source $file} result]} {
  messagebox -title $title -icon error \
	-message "[mc i00 [file tail $file]]:\n$result"
  exit
}

# Process user settings:
# replace commands resolved by current search path
# replace relative paths by absolute paths

# - commands
set cmds {java_cmd curl_cmd}
# - commands + folders + files
set list [concat $cmds ini_folder brouter_home]

set drive [regsub {((^.:)|(^//[^/]*)||(?:))(?:.*$)} $cwd {\1}]
if {$tcl_platform(os) == "Windows NT"}	{cd $env(SystemDrive)/}
if {$tcl_platform(os) == "Linux"}	{cd /}

foreach item $list {
  if {![info exists $item]} continue
  set value [set $item]
  if {$value == ""} continue
  if {$tcl_version >= 9.0} {set value [file tildeexpand $value]}
  if {$item in $cmds} {
    set exec [auto_execok $value]
    if {$exec == ""} {
      messagebox -title $title -icon error -message [mc e04 $value $item]
      exit
    }
    set value [lindex $exec 0]
  }
  switch [file pathtype $value] {
    absolute		{set $item [file normalize $value]}
    relative		{set $item [file normalize $cwd/$value]}
    volumerelative	{set $item [file normalize $drive/$value]}
  }
}

cd $cwd

# Check operating system

if {$tcl_platform(os) == "Windows NT"} {
  package require registry
  if {![info exists env(TMP)]} {set env(TMP) $env(HOME)]}
  set tmpdir [file normalize $env(TMP)]
  set null NUL
  set nprocs $env(NUMBER_OF_PROCESSORS)
} elseif {$tcl_platform(os) == "Linux"} {
  if {![info exists env(TMPDIR)]} {set env(TMPDIR) /tmp}
  set tmpdir $env(TMPDIR)
  set null /dev/null
  set nprocs [exec /usr/bin/nproc]
} else {
  error_message [mc e03 $tcl_platform(os)] exit
}

# Restore saved settings from folder ini_folder

if {![info exists ini_folder]} {set ini_folder "$env(HOME)/.GPX Tools"}
file mkdir $ini_folder

set tcp.port 17778
set track.profile ""
set track.variant 0
set turnpoint.export 6
set waypoint.export 0
set waypoint.labels 0
set waypoint.numbers 0
set gpx.folder [pwd]
set gpx.prefix om

set font.size [font configure TkDefaultFont -size]
set console.show 0
set console.geometry ""
set console.font.size 8

# Save/restore settings

proc save_settings {file args} {
  array set save {}
  set fd [open $file a+]
  seek $fd 0
  while {[gets $fd line] != -1} {
    regexp {^(.*?)=(.*)$} $line "" name value
    set save($name) $value
  }
  foreach name $args {set save($name) [set ::$name]}
  seek $fd 0
  chan truncate $fd
  foreach name [lsort [array names save]] {puts $fd $name=$save($name)}
  close $fd
}

proc restore_settings {file} {
  if {![file exists $file]} return
  set fd [open $file r]
  while {[gets $fd line] != -1} {
    regexp {^(.*?)=(.*)$} $line "" name value
    set ::$name $value
  }
  close $fd
}

# Restore saved settings

set settings [file rootname [file tail $script]].ini
restore_settings $ini_folder/$settings

# Restore saved font sizes

foreach item {TkDefaultFont TkTextFont TkFixedFont TkTooltipFont} \
	{font configure $item -size ${font.size}}

# Configure main window

set title [mc t00]
wm title . $title
wm protocol . WM_DELETE_WINDOW "set action 0"
wm resizable . 0 0
. configure -bd 5 -bg $colorBackground

# Output console window

set console 0;			# Valid values: 0=hide, 1=show

set ctid [thread::create -joinable "
  package require Tk
  wm withdraw .
  wm title . \"$title - [mc l99]\"
  set font_size ${console.font.size}
  set geometry {${console.geometry}}
  ttk::style theme use clam
  ttk::style configure . -border $colorBorder -troughcolor $colorTrough
  thread::wait
  "]

proc ctsend {script} "return \[send $ctid \$script\]"

ctsend {
  foreach item {Consolas "Ubuntu Mono" "Noto Mono" "Liberation Mono"
  	[font configure TkFixedFont -family]} {
    set family [lsearch -nocase -exact -inline [font families] $item]
    if {$family != ""} break
  }
  font create font -family $family -size $font_size
  text .txt -font font -wrap none -setgrid 1 -state disabled -undo 0 \
	-width 120 -xscrollcommand {.sbx set} \
	-height 24 -yscrollcommand {.sby set}
  ttk::scrollbar .sbx -orient horizontal -command {.txt xview}
  ttk::scrollbar .sby -orient vertical   -command {.txt yview}
  grid .txt -row 1 -column 1 -sticky nswe
  grid .sby -row 1 -column 2 -sticky ns
  grid .sbx -row 2 -column 1 -sticky we
  grid columnconfigure . 1 -weight 1
  grid rowconfigure    . 1 -weight 1

  bind .txt <Control-a> {%W tag add sel 1.0 end;break}
  bind .txt <Control-c> {tk_textCopy %W;break}
  bind . <Control-plus>  {incr_font_size +1}
  bind . <Control-minus> {incr_font_size -1}
  bind . <Control-KP_Add>      {incr_font_size +1}
  bind . <Control-KP_Subtract> {incr_font_size -1}

  bind . <Configure> {
    if {"%W" != "."} continue
    scan [wm geometry %W] "%%dx%%d+%%d+%%d" cols rows x y
    set geometry "$x $y $cols $rows"
  }

  proc incr_font_size {incr} {
    set px [.txt xview]
    set py [.txt yview]
    set size [font configure font -size]
    incr size $incr
    if {$size < 5 || $size > 20} return
    font configure font -size $size
    update idletasks
    .txt xview moveto [lindex $px 0]
    .txt yview moveto [lindex $py 0]
  }

  set lines 0
  proc write {text} {
    incr ::lines
    .txt configure -state normal
    if {[string index $text 0] == "\r"} {
      set text [string range $text 1 end]
      .txt delete end-2l end-1l
    }
    .txt insert end $text
    .txt configure -state disabled
    .txt see end
    if {$::lines == 256} {update; set ::lines 0}
  }

  proc show_hide {show} {
    if {$show} {
      if {$::geometry == ""} {
	wm deiconify .
      } else {
	lassign $::geometry x y cols rows
	if {$x > [expr [winfo vrootx .]+[winfo vrootwidth .]] ||
	    $x < [winfo vrootx .]} {set x [winfo vrootx .]}
	wm positionfrom . program
	wm geometry . ${cols}x${rows}+$x+$y
	wm deiconify .
	wm geometry . +$x+$y
      }
    } else {
      wm withdraw .
    }
  }

  foreach i {1 2} {
    lassign [chan pipe] fdi fdo
    thread::detach $fdo
    fconfigure $fdi -blocking 0 -buffering line -translation lf
    fileevent $fdi readable "
      while {\[gets $fdi line\] >= 0} {write \"\$line\\n\"}
    "
    set fdo$i $fdo
  }
}

set fdo [ctsend "set fdo1"]
thread::attach $fdo
fconfigure $fdo -blocking 0 -buffering line -translation lf
interp alias {} ::cputs {} ::puts $fdo

if {$console == 1} {
  set console.show 1
  ctsend "show_hide 1"
}

# Mark output message

proc cputw {text} {cputs "\[+++\] $text"}
proc cputi {text} {cputs "\[===\] $text"}
proc cputx {text} {cputs "\[···\] $text"}

cputw [mc m51 [pid] [file tail [info nameofexecutable]]]
cputw "Tcl/Tk version $tcl_patchLevel"
cputw "Script '[file tail $script]' version $version"

# Show error message

proc error_message {message exit_return} {
  messagebox -title $::title -icon error -message $message
  eval $exit_return
}

# Get shell command from exec command

proc get_shell_command {command} {
  return [join [lmap item $command {regsub {^(.* +.*|())$} $item {"\1"}}]]
}

# Check commands & folders

foreach item {java_cmd} {
  set value [set $item]
  if {$value == ""} {error_message [mc e04 $value $item] exit}
}
foreach item {brouter_home} {
  set value [set $item]
  if {![file isdirectory $value]} {error_message [mc e05 $value $item] exit}
}

# Work around Oracle's Java wrapper "java.exe" issue:
# Wrapper requires running within real Windows console,
# therefore not working within Tcl script called by "wish"!
# -> Try getting Java's real path from Windows registry

if {$tcl_platform(os) == "Windows NT" &&
  ([regexp -nocase {^.*/Program Files.*/Common Files/Oracle/Java/.*/java.exe$} $java_cmd]
   || [regexp -nocase {^.*/ProgramData/Oracle/Java/.*/java.exe$} $java_cmd])} {
  set exec ""
  foreach item {HKEY_LOCAL_MACHINE\\SOFTWARE\\JavaSoft \
		HKEY_LOCAL_MACHINE\\SOFTWARE\\WOW6432Node\\JavaSoft} {
    foreach key {JRE "Java Runtime Environment" JDK "Java Development Kit"} {
      if {[catch {registry get $item\\$key CurrentVersion} value]} continue
      if {[catch {registry get $item\\$key\\$value JavaHome} value]} continue
      set exec [auto_execok "[file normalize $value]/bin/java.exe"]
      if {$exec != ""} break
    }
    if {$exec == ""} continue
    set java_cmd [lindex $exec 0]
    break
  }
}

# Get major Java version

set java_version 0
set java_string unknown
set command [list $java_cmd -version]
set rc [catch "exec $command 2>@1" result]
if {!$rc} {
  set line [lindex [split $result \n] 0]
  regsub -nocase {^.* version "(.*)".*$} $line {\1} data
  set java_string $data
  if {[regsub {^1\.([1-9]+)\.[0-9]+.*$} $java_string {\1} data] > 0} {
    set java_version $data; # Oracle Java version <= 8
  } elseif {[regsub {^([1-9][0-9]*)((\.0)*\.[1-9][0-9]*)*([+-].*)?$} \
	$java_string {\1} data] > 0} {
    set java_version $data; # Other Java versions >= 9
  }
}

if {$rc || $java_version == 0} \
  {error_message [mc e08 Java [get_shell_command $command] $result] exit}
if {$java_version < 17} {error_message [mc e07 Java $java_string 17] exit}

# Check BRouter home folder for JAR file
# and subfolders profile and segments

set brouter_jar [lindex [glob -nocomplain -types f \
	-directory $brouter_home -tails *.jar] 0]
if {$brouter_jar == ""} {error_message [mc e10 $brouter_home] exit}
set segments_folder [lindex [glob -nocomplain -types d \
	-directory $brouter_home -tails segments*] 0]
if {$segments_folder == ""} {error_message [mc e11 $brouter_home] exit}
set profiles_folder [lindex [glob -nocomplain -types d \
	-directory $brouter_home -tails profiles*] 0]
if {$profiles_folder == ""} {error_message [mc e12 $brouter_home] exit}
set customs_folder [lindex [glob -nocomplain -types d \
	-directory $brouter_home -tails customprofiles*] 0]

# Evaluate numeric BRouter server version
# from output line of form "BRouter x.y.z / <date>"

set server_version 0
set server_string unknown
set command [list $java_cmd -cp $brouter_home/$brouter_jar btools.server.RouteServer]
set rc [catch "exec $command 2>@1" result]
foreach line [split $result \n] {
  if {![regexp -nocase {^(?:BRouter )([0-9.]+)(?:.*)$} $line "" data]} continue
  set server_string $data
  set data [split $data .]
  foreach item $data {set server_version [expr 100*$server_version+$item]}
  break
}

if {$rc || $server_version == 0} \
  {error_message [mc e08 Server [get_shell_command $command] $result] exit}
if {$server_version < 10707} \
  {error_message [mc e07 "BRouter Server" $server_string 1.7.7] exit}

# Looking for installed URL tool "curl"

set curl ""
if {[info exists curl_cmd] && $curl_cmd != ""} {set curl $curl_cmd}
if {$curl == ""} {set curl [lindex [auto_execok curl] 0]}
if {$curl == ""} {error_message [mc e15] exit}

catch {exec $curl -V} data
set string [lindex [split $data] 1]
set curl_version [split $string .]
set curl_version [expr 1000*[lindex $curl_version 0]+[lindex $curl_version 1]]
if {$curl_version < 7075} {error_message [mc e07 curl $string 7.75.0] exit}

# --- Begin of main window left column

# Title

font create title_font {*}[font configure TkDefaultFont] \
	-underline 1 -weight bold
label .title -text $title -font title_font -fg blue
pack .title -expand 1 -fill x -pady {0 3}

set github https://github.com/JFritzle/GPX-QMapShack-to-OruxMaps
tooltip .title $github
if {$tcl_platform(platform) == "windows"} \
	{set exec "exec cmd.exe /C START {} $github"}
if {$tcl_platform(os) == "Linux"} \
	{set exec "exec nohup xdg-open $github >/dev/null"}
bind .title <Button-1> "catch {$exec}"

# Left menu column

frame .l
pack .l -side left -anchor nw

# BRouter configuration

label .server_config -text [mc l01]
pack .server_config -in .l -expand 1 -fill x -pady 1

# BRouter server home folder

labelframe .server_home -labelanchor nw -text [mc l02]:
pack .server_home -in .l -expand 1 -fill x -pady 1
entry .server_home_value -textvariable brouter_home \
	-state readonly -takefocus 0 -highlightthickness 0
pack .server_home_value -in .server_home -expand 1 -fill x

# BRouter server version jar archive

labelframe .brouter_jar -labelanchor nw -text "[mc l03] $server_string:"
pack .brouter_jar -in .l -expand 1 -fill x -pady 1
entry .brouter_jar_value -textvariable brouter_jar \
	-state readonly -takefocus 0 -highlightthickness 0
tooltip .brouter_jar_value "Default: brouter.jar"
pack .brouter_jar_value -in .brouter_jar -expand 1 -fill x

# BRouter segments folder

labelframe .segments_folder -labelanchor nw -text [mc l04]:
pack .segments_folder -in .l -expand 1 -fill x -pady 1
entry .segments_folder_value -textvariable segments_folder \
	-state readonly -takefocus 0 -highlightthickness 0
tooltip .segments_folder_value "Default: segments4"
pack .segments_folder_value -in .segments_folder -expand 1 -fill x

# BRouter profiles folder

labelframe .profiles_folder -labelanchor nw -text [mc l05]:
pack .profiles_folder -in .l -expand 1 -fill x -pady 1
entry .profiles_folder_value -textvariable profiles_folder \
	-state readonly -takefocus 0 -highlightthickness 0
tooltip .profiles_folder_value "Default: profiles2"
pack .profiles_folder_value -in .profiles_folder -expand 1 -fill x

# BRouter custom profiles folder

labelframe .customs_folder -labelanchor nw -text [mc l06]:
pack .customs_folder -in .l -expand 1 -fill x -pady 1
entry .customs_folder_value -textvariable customs_folder \
	-state readonly -takefocus 0 -highlightthickness 0
tooltip .customs_folder_value "Default: customprofiles"
pack .customs_folder_value -in .customs_folder -expand 1 -fill x

# BRouter TCP port number

labelframe .tcp_port -labelanchor w -text [mc l07]:
entry .tcp_port_value -textvariable tcp.port \
	-width 6 -justify center
tooltip .tcp_port_value "1024 ≤ TCP-Port ≤ 65535"
pack .tcp_port -in .l -expand 1 -fill x -pady 1
pack .tcp_port_value -in .tcp_port \
	-side right -anchor e -expand 1 -padx {3 0}

# Validate TCP port number

.tcp_port_value configure -validate all -vcmd {
  set var [%W cget -textvariable]
  set val [string trim %P]
  if {"%V" == "key"} {
    return [regexp {^\d*$} $val];
  } elseif {"%V" == "focusin"} {
    set $var.prev $val
  } elseif {"%V" == "focusout"} {
    set prev [set $var.prev]
    if {[regexp {^\d+$} $val]} {
      if {$val <  1024} {set val $prev}
      if {$val > 65535} {set val $prev}
      set $var $val
    } else {
      set $var $prev
    }
    after idle "%W config -validate all"
  }
  return 1
}

# Separator

frame .sep -height 2 -bd 2 -relief sunken
pack .sep -in .l -expand 1 -fill x -pady 5

# Java runtime version

labelframe .jre_version -labelanchor w -text [mc l10]:
pack .jre_version -in .l -expand 1 -fill x -pady 1
label .jre_version_value -anchor e -textvariable java_string
pack .jre_version_value -in .jre_version \
	-side right -anchor e -expand 1

# Filler down to bottom left

frame .fill_l
pack .fill_l -in .l -fill y

# --- End of main window left column

# Menu columns separator

frame .m -width 2 -bd 2 -relief sunken
pack .m -side left -fill y -padx 5

# --- Begin of main window right column

# Right menu column

frame .r
pack .r -anchor nw -fill x

# Select GPX input files

labelframe .gpx_files -labelanchor nw -text [mc r10]:
pack .gpx_files -in .r -fill x -expand 1 -pady 1
set gpx_files {}
listbox .gpx_files_list -selectmode browse -activestyle none \
	-height 3 -listvariable gpx_files -state disabled
button .gpx_files_button -image ArrowDown -command choose_gpx_files
pack .gpx_files_button -in .gpx_files -side right -fill y -pady 1
pack .gpx_files_list -in .gpx_files -side left -fill x -expand 1

proc choose_gpx_files {} {
  set types [list [list [mc r11] .gpx]]
  set files [tk_getOpenFile -parent . -multiple 1 \
	-initialdir ${::gpx.folder} -filetypes $types \
	-title "$::title - [mc r10]"]
  if {![llength $files]} return
  set ::gpx.folder [file dirname [lindex $files 0]]
  set ::gpx_files [lmap file $files {lindex [file split $file] end}]
  set ::gpx_files [lsort -unique $::gpx_files]
}

# GPX output file prefix

labelframe .gpx_prefix -labelanchor w -text [mc r12]:
entry .gpx_prefix_value -textvariable gpx.prefix \
	-width 8 -justify left
pack .gpx_prefix -in .r -expand 1 -fill x -pady 1
pack .gpx_prefix_value -in .gpx_prefix \
	-side right -anchor e -expand 1 -padx {3 0}

# Validate file prefix for valid filename characters

.gpx_prefix_value configure -validate all -vcmd {
  set var [%W cget -textvariable]
  set val [string trim %P]
  if {"%V" == "key"} {
    return [regexp {^[^<>:;?"*|/\\]*$} $val];
  } elseif {"%V" == "focusin"} {
    set $var.prev $val
  } elseif {"%V" == "focusout"} {
    set prev [set $var.prev]
    if {[regexp {^[^<>:;?"*|/\\]+$} $val]} {
      set $var [string trimright $val .]
    } else {
      set $var $prev
    }
    after idle "%W config -validate all"
  }
  return 1
}

# Track profile

set list [glob -nocomplain -types f -directory \
	$brouter_home/$profiles_folder -tails *.brf]
set list [lmap item $list {regsub {.brf$} $item {}}]

set width 0
foreach item $list \
	{set width [expr max([font measure TkTextFont $item],$width)]}
set width [expr $width/[font measure TkTextFont "0"]+1]

labelframe .profile -labelanchor nw -text [mc r01]:
pack .profile -in .r -expand 1 -fill x -pady 1
combobox .profile_values -width $width \
	-validate key -validatecommand {return 0} \
	-textvariable track.profile -values $list
if {[.profile_values current] < 0} {.profile_values current 0}
pack .profile_values -in .profile -expand 1 -fill x

# Track variant

set list [mc r02l]

set width 0
foreach item $list \
	{set width [expr max([font measure TkTextFont $item],$width)]}
set width [expr $width/[font measure TkTextFont "0"]+1]

labelframe .variant -labelanchor w -text [mc r02]:
pack .variant -in .r -expand 1 -fill x -pady 1
combobox .variant_values -width $width \
	-validate key -validatecommand {return 0} \
	-values $list
if {[.variant_values current] < 0} {.variant_values current 0}
pack .variant_values -in .variant -side right

bind .variant_values <<ComboboxSelected>> {set track.variant [%W current]}

# Export turn instructions?

checkbutton .turnpoints -text [mc r03] -variable turnpoint.export \
	-offvalue 0 -onvalue 6

# Labeling turn instructions?

checkbutton .labels -text [mc r04] -variable waypoint.labels

# Numbering turn instructions?

checkbutton .numbers -text [mc r05] -variable waypoint.numbers

# Export track support waypoints?

checkbutton .waypoints -text [mc r06] -variable waypoint.export

foreach item {turnpoints labels numbers waypoints} {
  pack .$item -in .r -expand 1 -fill x -pady {2 0}
}

proc labels_onoff {} {
  .labels instate selected {.numbers state !disabled}
  .labels instate !selected {.numbers state disabled}
}
.labels configure -command labels_onoff
labels_onoff

# Action buttons

frame .buttons
button .buttons.continue -text [mc b01] -width 12 -command {set action 1}
button .buttons.cancel -text [mc b02] -width 12 -command {set action 0}
pack .buttons.continue .buttons.cancel -side left
pack .buttons -after .r -anchor n -pady 5

focus .buttons.continue

proc busy_state {state} {
  set busy {.l .r .buttons.continue}
  if {$state} {
    foreach item $busy {tk busy hold $item}
    .buttons.continue state pressed
    .buttons.cancel configure -text [mc b03] -command {set cancel 1}
  } else {
    .buttons.continue state !pressed
    .buttons.cancel configure -text [mc b02] -command {set action 0}
    foreach item $busy {tk busy forget $item}
  }
  update idletasks
}

# Show/hide output console window (show with saved geometry)

checkbutton .output -text [mc c99] -width 32 \
	-variable console.show -command show_hide_console
pack .output -after .buttons -anchor n -expand 1 -fill x

proc show_hide_console {} {ctsend "show_hide ${::console.show}";update}
show_hide_console

# Map/Unmap events are generated by Windows only!
set tid [thread::id]
ctsend "
  wm protocol . WM_DELETE_WINDOW \
	{thread::send -async $tid {.output invoke}}
  bind . <Unmap> {if {\"%W\" == \".\"} \
	{thread::send -async $tid {set console.show 0}}}
  bind . <Map>   {if {\"%W\" == \".\"} \
	{thread::send -async $tid {set console.show 1}}}
"

# --- End of main window right column

# Recalculate and force toplevel window size

proc resize_toplevel_window {widget} {
  update idletask
  lassign [wm minsize $widget] w0 h0
  set w1 [winfo reqwidth $widget]
  set h1 [winfo reqheight $widget]
  if {$w0 == $w1 && $h0 == $h1} return
  wm minsize $widget $w1 $h1
  wm maxsize $widget $w1 $h1
}

# Global toplevel bindings

bind . <Control-plus>  {incr_font_size +1}
bind . <Control-minus> {incr_font_size -1}
bind . <Control-KP_Add>      {incr_font_size +1}
bind . <Control-KP_Subtract> {incr_font_size -1}

# Save global settings to folder ini_folder

proc save_script_settings {} {
  scan [wm geometry .] "%dx%d+%d+%d" width height x y
  set ::window.geometry "$x $y $width $height"
  set ::font.size [font configure TkDefaultFont -size]
  set ::console.geometry [ctsend "set geometry"]
  set ::console.font.size [ctsend "font configure font -size"]
  save_settings $::ini_folder/$::settings \
	window.geometry font.size \
	console.show console.geometry console.font.size \
	tcp.port track.profile track.variant \
	turnpoint.export waypoint.export waypoint.labels waypoint.numbers \
	gpx.folder gpx.prefix
}

# Increase/decrease font size

proc incr_font_size {incr} {
  set size [font configure TkDefaultFont -size]
  if {$size < 0} {set size [expr round(-$size/[tk scaling])]}
  incr size $incr
  if {$size < 5 || $size > 20} return
  set fonts {TkDefaultFont TkTextFont TkFixedFont TkTooltipFont title_font}
  foreach item $fonts {font configure $item -size $size}
  set height [expr [winfo reqheight .title]-2]

  if {$::tcl_version > 8.6} {
    set scale [expr ($height+2)*0.0065]
    foreach item {CheckOff CheckOn RadioOff RadioOn} \
	{$item configure -format [list svg -scale $scale]}
  } else {
    set size [expr round(($height+3)*0.6)]
    set padx [expr round($size*0.3)]
    if {$::tcl_platform(os) == "Windows NT"} {set pady 0.1}
    if {$::tcl_platform(os) == "Linux"} {set pady -0.1}
    set pady [expr round($size*$pady)]
    set margin [list 0 $pady $padx 0]
    foreach item {TCheckbutton TRadiobutton} \
	{style configure $item -indicatorsize $size -indicatormargin $margin}
  }
  update idletasks

  resize_toplevel_window .
}

# Check selection for completeness

proc selection_ok {} {
  if {[llength $::gpx_files]} {return 1}
  error_message [mc e20] return
  return 0
}

# Start BRouter server as thread

set btid [thread::create -joinable "
    set fdo [ctsend "set fdo2"]
    thread::wait
  "]
proc btsend {script} "return \[send $btid \$script\]"

proc brouter_start {} {

  upvar #0 brouter_home home brouter_jar jar segments_folder segments \
	profiles_folder profiles customs_folder customs \
	tcp.port port nprocs maxthreads

  # Compose command line

  lappend params -Xmx128M -Xms128M -Xmn8M
  if {[info exists ::java_args]} {lappend params {*}$::java_args}

  lappend params -DmaxRunningTime=0 -DuseRFCMimeType=false
  lappend params -cp $home/$jar btools.server.RouteServer
  lappend params $home/$segments
  lappend params $home/$profiles
  lappend params $home/[expr {$customs != "" ? $customs : $profiles}]
  lappend params $port
  lappend params $maxthreads
  lappend params 127.0.0.1

  set fd [open $::tmpdir/java_args w]
  foreach item $params {puts $fd $item}
  close $fd
  lappend command $::java_cmd @$::tmpdir/java_args

  # Server's TCP port is currently in use?

  set text "BRouter Server \[SRV\]"
  set count 0
  while {$count < 5} {
    set rc [catch "socket -server {} -myaddr 127.0.0.1 $port" fd]
    if {!$rc} break
    incr count
    after 200
  }
  if {$rc} {
    error_message [mc m59 $text $port] return
    return
  }
  close $fd

  # Start server

  cputi "[mc m54 $text] ..."
  cputs [get_shell_command $command]

  btsend "set command {$command}"
  set rc [btsend {catch {open "| $command 2>@1" r} result}]

  if {$rc} {
    set result [btsend "set result"]
    error_message [mc m55 "$text: $result"] return
    return
  }

  btsend {
    thread::attach $fdo
    fconfigure $fdo -blocking 0 -buffering line -translation lf
    set fd $result
    fconfigure $fd -blocking 0 -buffering line -translation lf
    fileevent $fd readable "
      while {\[gets $fd line\] >= 0} {puts $fdo \"\\\[SRV\\\] \$line\"}
      set ready 1
    "
    vwait ready; # Wait until server is ready
  }

  namespace eval brouter {}
  namespace upvar brouter pid pid exe exe
  set pid [btsend {pid $fd}]
  set exe [file tail [lindex $command 0]]

  cputi [mc m51 $pid $exe]

}

# BRouter server stop

proc brouter_stop {} {

  if {![namespace exists brouter]} return

  namespace upvar brouter pid pid exe exe
  if {$::tcl_platform(os) == "Windows NT"} {catch {exec TASKKILL /F /PID $pid}}
  if {$::tcl_platform(os) == "Linux"} {catch {exec kill -SIGTERM $pid}}
  cputi [mc m52 $pid $exe]
  namespace delete brouter

}

# Get icon name from id

proc get_icon_name {id} {
  set i [lsearch -exact $::icons $id]
  return [expr {($i < 0) ? "" : [lindex $::icons $i+1]}]
}

# Get icon id from name

proc get_icon_id {name} {
  set i [lsearch -exact $::icons $name]
  return [expr {($i < 0) ? "" : [lindex $::icons $i-1]}]
}

# Convert all selected GPX files

proc run_convert_job {} {
  set ::cancel 0
  set cwd [pwd]
  cd ${::gpx.folder}
  while {[llength $::gpx_files]} {
    set ::gpx_files [lassign $::gpx_files file]
    convert_gpx_file $file
    if {$::cancel} break
  }	
  cd $cwd
}

# Convert GPX file QMapShack -> OruxMaps

proc convert_gpx_file {file} {
  cputi "[mc m61 $file] ..."
  set start [clock milliseconds]

  # Read GPX file
  set fd [open $file r]
  set data [read -nonewline $fd]
  close $fd

  # Check for creator
  regexp {(^.*<gpx.*?creator=")(.*?)(".*$)} $data {} head body tail
  cputx [mc m60 $body]
  # Replace creator
  set body "GPX-QMapShack-to-OruxMaps"
  set data $head$body$tail

  # Remvove some unnecessary QMS extensions
  regsub -all {<ql:history>.*?</ql:history>} $data {} data
  regsub -all {<ql:key>.*?</ql:key>} $data {} data
  regsub -all {<ql:bubble>.*?/>} $data {} data

  # Convert tracks of GPX file separately
  set result ""
  while {[regexp {^(.*?)(<trk>.*?</trk>)(.*)$} $data {} head body tail]} {
    append result [convert_gpx_waypoints $head]
    set data [convert_gpx_track $body]
    if {![string length $data]} {
      cputi [mc m67]
      return
    }
    append result $data
    set data $tail
  }
  append result [convert_gpx_waypoints $data]
  # Remove empty lines
  regsub -line -all {^\s*$\n?} $result {} result

  # Write converted GPX file
  set file ${::gpx.prefix}.$file
  set fd [open $file w]
  puts -nonewline $fd $result
  close $fd

  set stop [clock milliseconds]
  set time [expr ($stop-$start)/1000.]

  cputx [mc m65 $time]
  cputi [mc m64 $file]
}

# Convert GPX waypoints QMapShack -> OruxMaps

proc convert_gpx_waypoints {data} {
  # Map user defined QMS waypoints to OM waypoints
  set result ""
  while {[regexp {^(.*?)(<wpt.*?</wpt>)(.*)$} $data {} head body tail]} {
    append result $head
    regsub {^.*<sym>(.*?)</sym>.*$} $body {\1} sym
    set id [get_icon_id $sym]
    if {$id != ""} {
      regsub {^.*<name>(.*?)</name>.*$} $body {\1} name
      cputx "[mc m63 $name] ..."
      set string {<extensions><om:oruxmapsextensions xmlns:om="http://www.oruxmaps.com/oruxmapsextensions/1/0"><om:ext type="ICON" subtype="0">}
      append string $id
      append string {</om:ext></om:oruxmapsextensions></extensions>}
      regsub {(</wpt>)} $body "$string\\1" body
    }
    append result $body
    regsub {^.*<sym>(.*?)</sym>.*$} $body {\1} sym
    set data $tail
  }
  append result $data

  return $result
}

# Convert GPX track QMapShack -> OruxMaps

proc convert_gpx_track {track} {
  upvar #0 tcp.port port track.profile profile track.variant variant \
	waypoint.export waypoints turnpoint.export turnpoints \
	waypoint.labels labels waypoint.numbers numbers

  # Get track name
  regsub {^.*?(<trk>.*?<trkseg>).*$} $track {\1} trkhead
  regsub {^.*?<name>(.*?)</name>.*$} $trkhead {\1} trkname
  regsub {^(?:<!\[CDATA\[)(.*?)(?:\]\]>)$} $trkname {\1} trkname

  # Collect constraint track waypoints
  set trkpts [regexp -inline -all {<trkpt.*?</trkpt>} $track]
  set lonlats {}
  foreach item $trkpts {
    if {[regexp {.*<ql:flags>8</ql:flags>.*} $item]} continue
    set item [regsub {.*lon="(.*?)".*lat="(.*?)".*} $item {\1,\2}]
    set item [regsub {.*lat="(.*?)".*lon="(.*?)".*} $item {\2,\1}]
    lappend lonlats $item
  }
  cputx "[mc m62 $trkname [llength $lonlats]] ..."
  update idletasks

  # Let BRouter generate track from constraint track waypoints
  set url "http://127.0.0.1:$port/brouter"
  append url ?profile=$profile
  append url &alternativeidx=$variant
  append url &format=gpx
  append url &exportWaypoints=$waypoints
  append url &timode=$turnpoints
  append url &lonlats=[join $lonlats |]

  set cfg $::tmpdir/curl_config
  set fd [open $cfg w]
  puts $fd "url=$url"
  close $fd

  set command $::curl
  lappend command -qsk
  lappend command -K $cfg
  cputs [get_shell_command $command]

  set rc [catch {open "| $command 2>@1" r} result]
  if {$rc} {
    cputx [mc e16]
    return
  }

  update; # Force BRouter log output before reading BRouter reply

  set fd $result
  set data [read -nonewline $fd]
  close $fd

  if {![regexp {^\s*<.*} $data]} {
    if {$data == ""} {cputw [mc e17]} \
    else {cputs "\[SRV\] $data"}
    return ""
  }

  # Uncomment to output BRouter's GPX track
  #set fd [open track.$trkname.gpx w]
  #puts $fd $data
  #close $fd

  # BRouter generated track statistics
  regsub {.*<!-- (.*?) -->.*} $data {\1} info
  if {$info != ""} {cputx [mc m66 $info]}

  # Map BRouter waypoints to OM waypoints
  # Collect constraint track waypoints
  set n [regexp -all {<om:ext type="ICON" subtype="0">([0-9]+?)</om:ext>} $data]
  set f "%0[string length $n]d"
  set n 0
  set lonlats {}
  set tail $data
  set result ""
  while {1} {
    set i [string first "<wpt" $tail]
    set head [string range $tail 0 $i-1]
    set tail [string range $tail $i end]
    append result $head
    if {$i < 0} break
    set i [string first "</wpt>" $tail]
    set body [string range $tail 0 $i-1]
    set tail [string range $tail $i end]
    if {[regexp {.*<om:ext type="ICON" subtype="0">([0-9]+?)</om:ext>.*} \
	$body {} id]} {
      # OM direction waypoint
      lappend lonlats [regsub {.*lat="(.*?)".*lon="(.*?)".*} $body {\2,\1}]
      set name [get_icon_name $id]
      if {$name == ""} {set name Icon$id}
      set string "\n<sym>$name</sym>\n"
      if {$numbers} {set name "[format $f [incr n]] $name"}
      if {$labels} {append string "<name>$name</name>\n"}
      regsub {(<extensions>)} $body "$string\\1" body
    } elseif {[regsub {.*<type>(from)</type>.*} $body {38} id]} {
      # OM starting waypoint
      set name [get_icon_name $id]
      if {$name == ""} {set name Icon$id}
      set string "<sym>$name</sym>\n"
      if {$labels} {append string "<name>$name</name>\n"}
      regsub {<name>.*</type>} $body $string body
    } elseif {[regsub {.*<type>(to)</type>.*} $body {15} id]} {
      # OM finishing waypoint
      set name [get_icon_name $id]
      if {$name == ""} {set name Icon$id}
      set string "<sym>$name</sym>\n"
      if {$labels} {append string "<name>$name</name>\n"}
      regsub {<name>.*</type>} $body $string body
    } elseif {[regsub {.*<type>(via)</type>.*} $body {1} id]} {
      # OM support waypoint
      set string "<sym>Waypoint</sym>\n"
      regsub {<name>.*</type>} $body $string body
    }
    append result $body
  }
  append result $tail

  # Set QMS track flags depending on collected BRouter track waypoints:
  # flag = 0	... Constraint points, in QMS always visible
  # flag = 8	... Support points, in QMS visible as dots when editing track
  set tail $result
  set result ""
   while {1} {
    set i [string first "<trkpt" $tail]
    set head [string range $tail 0 $i-1]
    set tail [string range $tail $i end]
    append result $head
    if {$i < 0} break
    set i [string first "</trkpt>" $tail]
    set body [string range $tail 0 $i-1]
    set tail [string range $tail $i end]
    regsub {.*lon="(.*?)".*lat="(.*?)".*} $body {\1,\2} item
    set flag [expr {$item in $lonlats} ? 0 : 8]
    append body "<extensions><ql:flags>$flag</ql:flags></extensions>"
    append result $body
  }
  append result $tail

  # Replace BRouter generated track header by QMS track header
  regsub "<trk>.*?<trkseg>" $result $trkhead result
  # Remove BRouter track encapsulation
  regsub {^.*creator.*?>(.*)</gpx>.*$} $result {\1} result

  return $result
}

# Show main window (at saved position)

wm positionfrom . program
if {[info exists window.geometry]} {
  lassign ${window.geometry} x y width height
  # Adjust horizontal position if necessary
  set x [expr max($x,[winfo vrootx .])]
  set x [expr min($x,[winfo vrootx .]+[winfo vrootwidth .]-$width)]
  wm geometry . +$x+$y
}
incr_font_size 0
wm deiconify .

# Wait for valid selection or finish

while {1} {
  vwait action
  if {$action == 0} {
    save_script_settings
    exit
  }
  if {[selection_ok]} break
  unset action
}

# Create server's temporary files folder

append tmpdir /[format "GPX%8.8x" [pid]]
file mkdir $tmpdir

# Start Brouter server

brouter_start

# Wait for new selection or finish

if {[namespace exists brouter]} {
  update idletasks
  if {![info exists action]} {vwait action}
} else {
  set action 0
}

# After changing settings: run render job

while {$action == 1} {
  unset action
  if {[selection_ok]} {
    busy_state 1
    run_convert_job
    busy_state 0
  }
  if {![info exists action]} {vwait action}
}
unset action

# Stop BRouter server

brouter_stop

# Delete temporary files folder

catch {file delete -force $tmpdir}

# Unmap main toplevel window

wm withdraw .

# Save settings to folder ini_folder

save_script_settings

# Wait until output console window was closed

if {[ctsend "winfo ismapped ."]} {
  ctsend "
    write \"\n[mc m99]\"
    wm protocol . WM_DELETE_WINDOW {}
    bind . <ButtonRelease-3> {destroy .}
    tkwait window .
  "
}

# Done

destroy .
exit
