#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3
#pragma DefaultTab={3,20,4}
#pragma ModuleName=BatchRenamer
#pragma IgorVersion=8
#pragma version=1.99

#include <WaveSelectorWidget>
#include <Resize Controls>

// --------------------- Project Updater header ----------------------
// If you have installed or updated this project using the IgorExchange
// Projects Installer (http: www.igorexchange.com/project/Updater) you
// can be notified when new versions are released.
static constant kProjectID=21571 // the project node on IgorExchange
static strconstant ksShortTitle="Batch Renamer" // the project short title on IgorExchange

static strconstant ksPackageName = BatchRenamer
static strconstant ksPrefsFileName = acwBatchRenamer.bin
static constant kPrefsVersion = 105

// to do:
// proper help file!!

// When 'Wildcards' is checked, ? matches one character and * matches one
// or more characters. In the 'prefix', 'suffix' and 'replace with'
// fields, # represents a number. Use multiple # characters to set
// minimum number of digits. To insert a string by key from a wavenote,
// use the syntax {key[,keySepStr[,listSepStr[,matchCase]]]}, where the
// optional parameters correspond to those used in StringByKey. String
// parameters do not have to be quoted.
// DisplayHelpTopic "StringByKey" for details.

// execute batchrename(history=0) to prevent rename commands from being
// copied to history. This setting will be retained.

menu "Data"
	"Batch Rename", /Q, BatchRenamer#MakeBatchRenamerPanel()
end

// -------------- globally accessible function ---------------

function BatchRename([int history, int modal])
	if ((ParamIsDefault(history) + ParamIsDefault(modal)) < 2)
		STRUCT PackagePrefs prefs
		LoadPrefs(prefs)
		history = ParamIsDefault(history) ? prefs.options & 1 : history != 0
		modal = ParamIsDefault(modal) ? prefs.options & 2 : modal		
		prefs.options = (prefs.options & ~3) | (history + 2 * (modal != 0))
		SavePackagePreferences ksPackageName, ksPrefsFileName, 0, prefs
	endif
	MakeBatchRenamerPanel()
end

// ------------------ package preferences --------------------

static structure PackagePrefs
	uint32 version
	uint32 options // bit 0: history, bit 1: modal
	uchar replace
	uchar tokens
	STRUCT Rect win // window position and size, 8 bytes
	char reserved[128 - 8 - 2 - 8]
endstructure

// set prefs structure to default values
static function PrefsSetDefaults(STRUCT PackagePrefs &prefs)
	prefs.version    = kPrefsVersion
	prefs.options    = 1
	prefs.replace    = 1
	prefs.tokens     = 0
	prefs.win.left   = 20
	prefs.win.top    = 20
	prefs.win.right  = 20 + 550
	prefs.win.bottom = 20 + 340
	int i
	for(i=0;i<(128-18);i+=1)
		prefs.reserved[i] = 0
	endfor
end

static function LoadPrefs(STRUCT PackagePrefs &prefs)
	LoadPackagePreferences /MIS=1 ksPackageName, ksPrefsFileName, 0, prefs
	if (V_flag!=0 || V_bytesRead==0 || prefs.version!=kPrefsVersion)
		PrefsSetDefaults(prefs)
	endif
end

// save window position in package prefs
static function SaveWindowPosition(string strWin)
	STRUCT PackagePrefs prefs
	LoadPrefs(prefs)
	// save window position
	GetWindow $strWin wsizeRM
	prefs.win.top = v_top
	prefs.win.left = v_left
	prefs.win.bottom = v_bottom
	prefs.win.right = v_right
	SavePackagePreferences ksPackageName, ksPrefsFileName, 0, prefs
end

static function /DF ResetListboxWaves()
	NewDataFolder /O root:Packages
	NewDataFolder /O root:Packages:BatchRenamer
	DFREF dfr = root:Packages:BatchRenamer
	Make /O/N=0/T dfr:wPaths
	Make /O/N=(0,4)/T dfr:NamesListWave /wave=NamesListWave
	// ⊗ doesn't display nicely on Windows
	setDimLabels("\JC≡;CurrentName;NewName;\JC⊗;", 1, NamesListWave)
	Make/O/B/U/N=(0,4,3) dfr:sw /wave=sw
	setDimLabels(";backColors;foreColors;", 2, sw)
	Make/N=(2,3)/O/W/U dfr:wcolor /wave=wcolor
	wcolor[1][] = {{0xFFFF},{0x0000},{0x0000}} // red
	wcolor[2][] = {{0x0000},{0x0000},{0xFFFF}} // blue
	wcolor[3][] = {{0xFFFF},{0xEA60},{0xEA60}} // pink
	wcolor[4][] = {{0x0002},{0x9999},{0x0001}} // dark green
	string /G dfr:strFilter = ""
	return dfr
end

static function MakeBatchRenamerPanel()
	
	DoWindow /K BatchRenamerPanel
	
	STRUCT PackagePrefs prefs
	LoadPrefs(prefs)
		
	// create package data folder & waves
	DFREF dfr = ResetListboxWaves()
	wave /T/SDFR=dfr wPaths, NamesListWave
	wave /SDFR=dfr sw, wcolor
	
	int isWin = 0
	#ifdef WINDOWS
	isWin = 1 // this will be used to fix the positioning of controls for Windows
	#endif

	NewPanel /K=1/N=BatchRenamerPanel/W=(prefs.win.left,prefs.win.top,prefs.win.right,prefs.win.bottom) as "Batch Renamer"	
	ModifyPanel /W=BatchRenamerPanel, noEdit=1
	
	DefineGuide/W=BatchRenamerPanel FGc={FL,0.5,FR}
	DefineGuide/W=BatchRenamerPanel FGcr={FGc,0.5,FR}
	DefineGuide/W=BatchRenamerPanel cmdR={FR,-10}
	DefineGuide/W=BatchRenamerPanel cmdT={FT,0.75,FB}
	DefineGuide/W=BatchRenamerPanel cmdB={FB,-40}
	NewNotebook /F=1/N=nbCmd/HOST=BatchRenamerPanel/W=(10,10,190,35)/FG=($"",cmdT,cmdR,cmdB)/OPTS=11
	
	Notebook BatchRenamerPanel#nbCmd fSize=12-2*isWin, showRuler=0
	Notebook BatchRenamerPanel#nbCmd spacing={4,0,5}, changeableByCommandOnly=1
	Notebook BatchRenamerPanel#nbCmd margins={0,0,435}, backRGB=(60066,60076,60063)
	SetWindow BatchRenamerPanel#nbCmd activeChildFrame=0
	SetActiveSubwindow BatchRenamerPanel

	// insert a notebook subwindow to be used for filtering lists
	DefineGuide/W=BatchRenamerPanel fgb={cmdT,-5}
	DefineGuide/W=BatchRenamerPanel fgt={cmdT,-22}
	DefineGuide/W=BatchRenamerPanel fgr={FGc,-82}
	NewNotebook /F=1/N=nbFilter/HOST=BatchRenamerPanel/W=(10,500,5200,1000)/FG=($"",fgt,fgr,fgb)/OPTS=3
	Notebook BatchRenamerPanel#nbFilter fSize=12-3*isWin, showRuler=0
	Notebook BatchRenamerPanel#nbFilter spacing={1, 0, 0}
	Notebook BatchRenamerPanel#nbFilter margins={0,0,1000}
	SetWindow BatchRenamerPanel#nbFilter activeChildFrame=0
	ClearText(1) // sets notebook to its default appearance
	SetActiveSubwindow BatchRenamerPanel
	
	// make a Button for clearing text in notebook subwindow
	Button ButtonClear, win=BatchRenamerPanel,pos={196,234},size={15,15},title=""
	Button ButtonClear, win=BatchRenamerPanel, Picture=BatchRenamer#ClearTextPicture,Proc=BatchRenamer#ButtonFunc, disable=1
	
	PopupMenu popupType, win=BatchRenamerPanel, pos={10, 5}, value="Waves;Variables;Strings;DataFolders;"
	PopupMenu popupType, win=BatchRenamerPanel, Proc=BatchRenamer#PopMenuFunc
	PopupMenu popupType, win=BatchRenamerPanel, help={"Select an object type to display in the browser below"}
		
	CheckBox checkWC, win=BatchRenamerPanel,pos={280,8},size={15,15},title="Wildcards",value=(prefs.replace==1),mode=1, Proc=BatchRenamer#CheckFunc
	CheckBox checkWC, win=BatchRenamerPanel, help={"Use ? and * to replace one and multiple characters"}
	CheckBox checkRegEx, win=BatchRenamerPanel,pos={350,8},size={15,15},title="RegEx",value=(prefs.replace==2),mode=1, Proc=BatchRenamer#CheckFunc
	CheckBox checkRegEx, win=BatchRenamerPanel, help={"Use a regular expression to select parts of names to substitute"}
	CheckBox checkString, win=BatchRenamerPanel,pos={401,8},size={15,15},title="String",value=(prefs.replace==0),mode=1, Proc=BatchRenamer#CheckFunc
	CheckBox checkString, win=BatchRenamerPanel, help={"Use ReplaceString substitution"}
	CheckBox checkTokens, win=BatchRenamerPanel,pos={456,8},size={15,15},title="##, {..} tokens",value=prefs.tokens, mode=0, Proc=BatchRenamer#CheckFunc
	CheckBox checkTokens, win=BatchRenamerPanel, help={"# in replacement string substitutes a digit, {} substitutes text from wavenote"}
	
	SetVariable setvarThis, win=BatchRenamerPanel, pos={280,30}, size={125,14}, title="Replace"
	SetVariable setvarThis, win=BatchRenamerPanel, value=_STR:"", Proc=BatchRenamer#SetVarFunc, focusRing=0
	SetVariable setvarThis, win=BatchRenamerPanel, help={"Replace specified text in all item names"}
	SetVariable setvarWith, win=BatchRenamerPanel, pos={408,30}, size={80,14}, title="with"
	SetVariable setvarWith, win=BatchRenamerPanel, value=_STR:"", Proc=BatchRenamer#SetVarFunc, focusRing=0
	SetVariable setvarWith, win=BatchRenamerPanel, help={"Replace specified text in all item names"}
	CheckBox checkMaxReplace, win=BatchRenamerPanel, pos={492,28}, size={15,15}, title="1 time", value=1, mode=0, Proc=BatchRenamer#CheckFunc
	CheckBox checkMaxReplace, win=BatchRenamerPanel, help={"Limits maximum number of replacements to 1 per item when checked"}, disable=2*(prefs.replace>0)
		
	SetVariable setvarPrefix, win=BatchRenamerPanel, pos={280,50}, size={85,14}, title="Prefix:"
	SetVariable setvarPrefix, win=BatchRenamerPanel, value=_STR:"", Proc=BatchRenamer#SetVarFunc, focusRing=0
	SetVariable setvarPrefix, win=BatchRenamerPanel, help={"Prepend this text to all item names"}
	SetVariable setvarSuffix, win=BatchRenamerPanel, pos={373,50}, size={85,14}, title="Suffix:"
	SetVariable setvarSuffix, win=BatchRenamerPanel, value=_STR:"", Proc=BatchRenamer#SetVarFunc, focusRing=0
	SetVariable setvarSuffix, win=BatchRenamerPanel, help={"Append this text to all item names"}
	SetVariable setvarStartNum, win=BatchRenamerPanel, pos={467,50}, size={70,14}, title="# starts at"
	SetVariable setvarStartNum, win=BatchRenamerPanel, value=_NUM:0, Proc=BatchRenamer#SetVarFunc, focusRing=0, limits={0,Inf,0}
	SetVariable setvarStartNum, win=BatchRenamerPanel, help={"Set start of numbering for # substitution"}
		
	ListBox listboxSelector, win=BatchRenamerPanel, pos={10,30}, size={200,200}, focusRing=0
	MakeListIntoWaveSelector("BatchRenamerPanel", "listboxSelector", content=WMWS_Waves, nameFilterProc="BatchRenamer#filterFunc")
	WS_SetNotificationProc("BatchRenamerPanel", "listboxSelector", "BatchRenamer#WS_NotificationProc")
	WS_OpenAFolderFully("BatchRenamerPanel", "listboxSelector", GetDataFolder(1))
		
	ListBox listboxRenamer, win=BatchRenamerPanel, pos={280,70}, size={260,180}, focusRing=0, listWave=NamesListWave, widths={4,20,20,4}
	ListBox listboxRenamer, win=BatchRenamerPanel, Proc=BatchRenamer#ListboxFunc, selwave=dfr:sw, colorWave=wcolor, userColumnResize=1
	ListBox listboxRenamer, win=BatchRenamerPanel, mode=9
	
	Button buttonSelect, win=BatchRenamerPanel, pos={220,130}, size={50,20}, fsize=14, title="→", valueColor=(0,0,65535), fstyle=1
	Button buttonSelect, win=BatchRenamerPanel, Proc=BatchRenamer#ButtonFunc
	Button buttonSelect, win=BatchRenamerPanel, help={"Click here to move selected items from the browser on the left to the rename list on the right"}
	Button buttonDoIt, win=BatchRenamerPanel, pos={15,313}, size={55,20}, fsize=14, title="Do It"
	Button buttonDoIt, win=BatchRenamerPanel, Proc=BatchRenamer#ButtonFunc, disable=2
	Button buttonCmd, win=BatchRenamerPanel, pos={90,313}, size={105,20}, fsize=14, title="To Cmd Line"
	Button buttonCmd, win=BatchRenamerPanel, Proc=BatchRenamer#ButtonFunc, disable=2
	Button buttonClip, win=BatchRenamerPanel, pos={215,313}, size={75,20}, fsize=14, title="To Clip"
	Button buttonClip, win=BatchRenamerPanel, Proc=BatchRenamer#ButtonFunc, disable=2
	Button buttonHelp, win=BatchRenamerPanel, pos={390,313}, size={60,20}, fsize=14, title="Help"
	Button buttonHelp, win=BatchRenamerPanel, Proc=BatchRenamer#ButtonFunc
	Button buttonCancel, win=BatchRenamerPanel, pos={470,313}, size={65,20}, fsize=14, title="Cancel"
	Button buttonCancel, win=BatchRenamerPanel, Proc=BatchRenamer#ButtonFunc
	
	SetWindow BatchRenamerPanel hook(hFilterHook)=BatchRenamer#FilterHook
	
	// resizing userdata for controls
	Button buttonClear,userdata(ResizeControlsInfo) = A"!!,GT!!#B$!!#<(!!#<(z!!#N3Bk1ct7Rpqgzzzzzzzzzzzzz!!#N3Bk1ct7Rpqgz"
	Button buttonClear,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#N3Bk1ct@r5aUzzzzzzzzzz"
	Button buttonClear,userdata(ResizeControlsInfo) += A"zzz!!#N3Bk1ct@r5aUzzzzzzzzzzzzz!!!"
	PopupMenu popupType,userdata(ResizeControlsInfo)= A"!!,A.!!#9W!!#?K!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popupType,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu popupType,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
		
	CheckBox checkWC,userdata(ResizeControlsInfo) = A"!!,HG!!#:b!!#?-!!#<(z!!#N3Bk1ct7Rpqgzzzzzzzzzzzzz!!#N3Bk1ct7Rpqgz"
	CheckBox checkWC,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:DuaTbBQO4Szzzzzzzzzz"
	CheckBox checkWC,userdata(ResizeControlsInfo) += A"zzz!!#u:Du_\"OASGdjF8u:@zzzzzzzzzzzz!!!"
	CheckBox checkRegEx,userdata(ResizeControlsInfo)= A"!!,Hj!!#:b!!#>>!!#<(z!!#N3Bk1ct7Rpqgzzzzzzzzzzzzz!!#N3Bk1ct7Rpqgz"
	CheckBox checkRegEx,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:DuaTbBQO4Szzzzzzzzzz"
	CheckBox checkRegEx,userdata(ResizeControlsInfo) += A"zzz!!#u:Du_\"OASGdjF8u:@zzzzzzzzzzzz!!!"
	CheckBox checkString,userdata(ResizeControlsInfo)= A"!!,I.J,hk8!!#>:!!#<(z!!#N3Bk1ct7Rpqgzzzzzzzzzzzzz!!#N3Bk1ct7Rpqgz"
	CheckBox checkString,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:DuaTbBQO4Szzzzzzzzzz"
	CheckBox checkString,userdata(ResizeControlsInfo) += A"zzz!!#u:Du_\"OASGdjF8u:@zzzzzzzzzzzz!!!"
	CheckBox checkTokens,userdata(ResizeControlsInfo)= A"!!,IJ!!#:b!!#?W!!#<8z!!#N3Bk1ct7Rpqgzzzzzzzzzzzzz!!#N3Bk1ct7Rpqgz"
	CheckBox checkTokens,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:DuaTbBQO4Szzzzzzzzzz"
	CheckBox checkTokens,userdata(ResizeControlsInfo) += A"zzz!!#u:Du_\"OASGdjF8u:@zzzzzzzzzzzz!!!"
			
	SetVariable setvarThis,userdata(ResizeControlsInfo) = A"!!,HG!!#=S!!#@^!!#;mz!!#N3Bk1ct7Rpqgzzzzzzzzzzzzz!!#N3Bk1ct7Rps/z"
	SetVariable setvarThis,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvarThis,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvarWith,userdata(ResizeControlsInfo) = A"!!,I2!!#=S!!#?Y!!#;mz!!#N3Bk1ct7Rps/zzzzzzzzzzzzz!!#o2B4uAe7Rpqgz"
	SetVariable setvarWith,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvarWith,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox checkMaxReplace,userdata(ResizeControlsInfo)= A"!!,I\\!!#=C!!#>:!!#<8z!!#o2B4uAe7Rpqgzzzzzzzzzzzzz!!#o2B4uAe7Rpqgz"
	CheckBox checkMaxReplace,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:DuaTbBQO4Szzzzzzzzzz"
	CheckBox checkMaxReplace,userdata(ResizeControlsInfo) += A"zzz!!#u:Du_\"OASGdjF8u:@zzzzzzzzzzzz!!!"

	SetVariable setvarPrefix,userdata(ResizeControlsInfo) = A"!!,HG!!#>V!!#?c!!#;mz!!#N3Bk1ct7Rpqgzzzzzzzzzzzzz!!#N3Bk1ct7Rps/z"
	SetVariable setvarPrefix,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvarPrefix,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvarSuffix,userdata(ResizeControlsInfo) = A"!!,HuJ,ho,!!#?c!!#;mz!!#N3Bk1ct7Rps/zzzzzzzzzzzzz!!#o2B4uAe7Rpqgz"
	SetVariable setvarSuffix,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvarSuffix,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvarStartNum,userdata(ResizeControlsInfo)= A"!!,IOJ,ho,!!#?E!!#;mz!!#o2B4uAe7Rpqgzzzzzzzzzzzzz!!#o2B4uAe7Rpqgz"
	SetVariable setvarStartNum,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:DuaTbBQO4Szzzzzzzzzz"
	SetVariable setvarStartNum,userdata(ResizeControlsInfo) += A"zzz!!#u:Du_\"OASGdjF8u:@zzzzzzzzzzzz!!!"

	ListBox listboxSelector,userdata(ResizeControlsInfo) = A"!!,A.!!#=S!!#AW!!#AWz!!#](Aon\"Qzzzzzzzzzzzzzz!!#N3Bk1ct7Rpqgz"
	ListBox listboxSelector,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	ListBox listboxSelector,userdata(ResizeControlsInfo) += A"zzz!!#N3Bk1ct@r5aUzzzzzzzzzzzzz!!!"
	ListBox listboxRenamer,userdata(ResizeControlsInfo) = A"!!,HG!!#?E!!#B<!!#ACz!!#N3Bk1ct7Rpqgzzzzzzzzzzzzz!!#o2B4uAezz"
	ListBox listboxRenamer,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	ListBox listboxRenamer,userdata(ResizeControlsInfo) += A"zzz!!#N3Bk1ct@r5aUzzzzzzzzzzzzz!!!"
	Button buttonSelect,userdata(ResizeControlsInfo) = A"!!,Gl!!#@f!!#>V!!#<Xz!!#N3Bk1ct7Rpqgzzzzzzzzzzzzz!!#N3Bk1ct7Rpqgz"
	Button buttonSelect,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!\";f87cLJBQO5Rzzzzzzzzzz"
	Button buttonSelect,userdata(ResizeControlsInfo) += A"zzz!!#r+D.Oh\\ASGdjF8u:@zzzzzzzzzzzz!!!"
	Button buttonDoIt,userdata(ResizeControlsInfo) = A"!!,B)!!#BVJ,ho@!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button buttonDoIt,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	Button buttonDoIt,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	Button buttonCmd,userdata(ResizeControlsInfo) = A"!!,En!!#BVJ,hpa!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button buttonCmd,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	Button buttonCmd,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	Button buttonClip,userdata(ResizeControlsInfo) = A"!!,Gg!!#BVJ,hp%!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button buttonClip,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	Button buttonClip,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	Button buttonHelp,userdata(ResizeControlsInfo) = A"!!,I)!!#BVJ,hoT!!#<Xz!!#o2B4uAezzzzzzzzzzzzzz!!#o2B4uAezz"
	Button buttonHelp,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	Button buttonHelp,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	Button buttonCancel,userdata(ResizeControlsInfo)= A"!!,IQ!!#BVJ,hof!!#<Xz!!#o2B4uAezzzzzzzzzzzzzz!!#o2B4uAezz"
	Button buttonCancel,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	Button buttonCancel,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	
	// resizing userdata for panel
	SetWindow kwTopWin,userdata(ResizeControlsInfo) = A"!!*'\"z!!#CnJ,hs:zzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzzzzzzzzz!!!"
	SetWindow kwTopWin,userdata(ResizeControlsGuides) = "FGc;FGcr;cmdR;cmdT;cmdB;fgb;fgt;fgr;"
	SetWindow kwTopWin,userdata(ResizeControlsInfoFGc) = "NAME:FGc;WIN:BatchRenamerPanel;TYPE:User;HORIZONTAL:0;POSITION:275.00;GUIDE1:FL;GUIDE2:FR;RELPOSITION:0.5;"
	SetWindow kwTopWin,userdata(ResizeControlsInfocmdR) = "NAME:cmdR;WIN:BatchRenamerPanel;TYPE:User;HORIZONTAL:0;POSITION:540.00;GUIDE1:FR;GUIDE2:;RELPOSITION:-10;"
	SetWindow kwTopWin,userdata(ResizeControlsInfocmdT) = "NAME:cmdT;WIN:BatchRenamerPanel;TYPE:User;HORIZONTAL:1;POSITION:255.00;GUIDE1:FT;GUIDE2:FB;RELPOSITION:0.75;"
	SetWindow kwTopWin,userdata(ResizeControlsInfocmdB) = "NAME:cmdB;WIN:BatchRenamerPanel;TYPE:User;HORIZONTAL:1;POSITION:300.00;GUIDE1:FB;GUIDE2:;RELPOSITION:-40;"
	SetWindow kwTopWin,userdata(ResizeControlsInfofgb) = "NAME:fgb;WIN:BatchRenamerPanel;TYPE:User;HORIZONTAL:1;POSITION:250.00;GUIDE1:cmdT;GUIDE2:;RELPOSITION:-5;"
	SetWindow kwTopWin,userdata(ResizeControlsInfofgt) = "NAME:fgt;WIN:BatchRenamerPanel;TYPE:User;HORIZONTAL:1;POSITION:233.00;GUIDE1:cmdT;GUIDE2:;RELPOSITION:-22;"
	SetWindow kwTopWin,userdata(ResizeControlsInfofgr) = "NAME:fgr;WIN:BatchRenamerPanel;TYPE:User;HORIZONTAL:0;POSITION:193.00;GUIDE1:FGc;GUIDE2:;RELPOSITION:-82;"
	SetWindow kwTopWin,userdata(ResizeControlsInfoFGcr) = "NAME:FGcr;WIN:BatchRenamerPanel;TYPE:User;HORIZONTAL:0;POSITION:412.00;GUIDE1:FGc;GUIDE2:FR;RELPOSITION:0.5;"

	// resizing panel hook
	SetWindow BatchRenamerPanel hook(ResizeControls)=ResizeControls#ResizeControlsHook
	ResizeControls#FitAllControlsToWin("BatchRenamerPanel") // just to be sure
		
	SetWindow BatchRenamerPanel userdata(version) = num2str(ProcedureVersion(""))
	
	if (prefs.options & 2)
		PauseForUser BatchRenamerPanel
	endif
end

static function fillPanelStructure(STRUCT PanelStatusStructure &s)
	getControlValue("BatchRenamerPanel", "popupType", s.type)
	getControlValue("BatchRenamerPanel", "setvarPrefix", s.prefix)
	getControlValue("BatchRenamerPanel", "setvarSuffix", s.suffix)
	getControlValue("BatchRenamerPanel", "setvarThis", s.this)
	getControlValue("BatchRenamerPanel", "setvarWith", s.with)
	getControlValue("BatchRenamerPanel", "listboxSelector", s.selector)
	getControlValue("BatchRenamerPanel", "listboxRenamer", s.renamer)
	getControlValue("BatchRenamerPanel", "checkMaxReplace", s.checkMax)
	getControlValue("BatchRenamerPanel", "checkWC", s.wildcards)
	getControlValue("BatchRenamerPanel", "checkRegEx", s.regex)
	getControlValue("BatchRenamerPanel", "checkTokens", s.tokens)
	getControlValue("BatchRenamerPanel", "setvarStartNum", s.startNum)
end

static structure PanelStatusStructure
	STRUCT ControlValueStructure type, prefix, suffix, this, with, selector, renamer, checkMax, wildcards, regex, tokens, startNum
endstructure

static structure ControlValueStructure
	int16 type
	string ctrlName
	variable value
	string sval
	STRUCT RGBColor rgb
	STRUCT RGBAColor rgba
	variable selcol
endstructure

static function GetControlValue(string win, string controlName, STRUCT ControlValueStructure &s)
	ControlInfo /W=$win $controlName
	s.ctrlName = controlName
	s.type = v_flag
	switch (abs(V_Flag))
		case 3: // popup menu
			s.rgb.red = V_Red; s.rgb.green = V_Green; s.rgb.blue = V_Blue
			s.rgba.red = V_Red; s.rgba.green = V_Green; s.rgba.blue = V_Blue
			s.rgba.alpha = V_Alpha
		case 2: // checkbox
		case 4: // valdisplay
		case 5: // SetVariable
		case 7: // slider
		case 8: // tab
			s.value = v_value
			s.sval = s_value
			break
		case 11: // listbox
			s.value = v_value
			s.sval = s_value
			s.selcol = v_selcol
			break
	endswitch
end

static function ValidCell(STRUCT WMListboxAction &s)
	return s.row>-1 && s.col>-1 && s.row<DimSize(s.listWave, 0) && s.col<DimSize(s.listWave, 1)
end

// this function enables the deleterow 'button'
static function ListboxFunc(STRUCT WMListboxAction &s)
	
	DragReorder(s)
	
	if (s.eventCode==2 && s.row==-1 && s.col==1 && s.eventmod!=1) // click in column heading - resort listbox waves
		resort(s)
		SetNewNames()
	endif
	
	if (s.eventCode==1 && s.col==3) // mousedown
		if (ValidCell(s) == 0)
			return 0
		endif
		ListBox $s.ctrlName, win=$s.win, userdata(mousedownrow)=num2str(s.row)
	endif
		
	if (s.eventCode==2 && s.col==3 && s.row>-1 && s.row<DimSize(s.listWave,0)) // mouseup
		int mousedownrow=str2num(GetUserData(s.win,s.ctrlName,"mousedownrow"))
		if (s.row==mousedownrow)
			wave /T wPaths=root:Packages:BatchRenamer:wPaths
			//wave sw=root:Packages:BatchRenamer:sw
			DeletePoints /M=0 s.row, 1, wPaths, s.listWave, s.selwave
			if(DimSize(s.listWave,0) == 0) // when the last row is deleted the wave becomes 1D
				Redimension /N=(0,4) s.listWave
				setDimLabels("\JC≡;CurrentName;NewName;\JC⊗;", 1, s.listWave)
				Redimension /N=(0,4,3) s.selwave
				setDimLabels(";backColors;foreColors;", 2, s.selwave)
			endif
			generateCmd()
		endif
	endif
	
	if (s.eventCode == 2) // mouseup
		ListBox $s.ctrlName, win=$s.win, userdata(mousedownrow)=""
	endif
	
	if (s.eventCode==12 && (s.row==8 || s.row==127)) // backspace or delete
		int i
		wave /T wPaths=root:Packages:BatchRenamer:wPaths
		for(i=DimSize(s.listWave, 0)-1;i>=0;i-=1)
			if (s.selwave[i][0][0])
				DeletePoints /M=0 i, 1, wPaths, s.listWave, s.selwave
			endif
		endfor
		if (DimSize(s.listWave,0) == 0) // when the last row is deleted the wave becomes 1D
			Redimension /N=(0,4) s.listWave
			setDimLabels("\JC≡;CurrentName;NewName;\JC⊗;", 1, s.listWave)
			Redimension /N=(0,4,3) s.selwave
			setDimLabels(";backColors;foreColors;", 2, s.selwave)
		endif
		generateCmd()
	endif
		
	if (s.eventCode == 11) // column resize
		ControlInfo /W=$(s.win) $(s.ctrlName)
		variable c1, c2, c3, c4
		sscanf S_columnWidths, "%g,%g,%g,%g", c1, c2, c3, c4
		c1/=10; c2/=10; c3/=10; c4/=10
		ListBox $(s.ctrlName) win=$(s.win), widths={c1, c2, c3, c4}
	endif
	return 0
end

static function resort(STRUCT WMListboxAction &s)
	variable sortorder = str2num(GetUserData(s.win, s.ctrlName, "sortorder"))
	wave /T wPaths = root:Packages:BatchRenamer:wPaths
	if (sortorder == 1)
		SortColumns /R/A/KNDX={1} sortwaves={s.listwave, s.selwave, wPaths}
		ListBox $s.ctrlName, win=$s.win, userdata(sortorder)="-1"
	else
		SortColumns /A/KNDX={1} sortwaves={s.listwave, s.selwave, wPaths}
		ListBox $s.ctrlName, win=$s.win, userdata(sortorder)="1"
	endif
end
	
static function CheckFunc(STRUCT WMCheckboxAction &s)
	
	if(s.eventcode != 2)
		return 0
	endif
	
	if (CheckUpdated(s.win, 1))
		return 0
	endif
	
	STRUCT PackagePrefs prefs
	LoadPrefs(prefs)
		
	strswitch (s.ctrlName)
		case "checkWC" :
			prefs.replace = 1
			CheckBox checkMaxReplace, win=BatchRenamerPanel, value = 1
			break
		case "checkRegEx" :
			prefs.replace = 2
			CheckBox checkMaxReplace, win=BatchRenamerPanel, value = 1
			break
		case "checkString" :
			prefs.replace = 0
			break
		case "checkTokens" :
			prefs.tokens = s.checked
			break
	endswitch
	
	SavePackagePreferences ksPackageName, ksPrefsFileName, 0, prefs
	
	CheckBox checkWC, win=BatchRenamerPanel, value=(prefs.replace==1)
	CheckBox checkRegEx, win=BatchRenamerPanel, value=(prefs.replace==2)
	CheckBox checkString, win=BatchRenamerPanel, value=(prefs.replace==0)
	CheckBox checkMaxReplace, win=BatchRenamerPanel, value = 1, disable=2*(prefs.replace>0)
	
	setNewNames()
	return 0
end

static function SetVarFunc(STRUCT WMSetVariableAction &s)	
	if (s.eventcode == 8)
		if (CheckUpdated(s.win, 1))
			return 0
		endif
		SetNewNames()
	endif
	return 0
end

static function PopMenuFunc(STRUCT WMPopupAction &pa)
	if (pa.eventCode != 2)
		return 0
	endif
	if (CheckUpdated(pa.win, 0))
		return 0
	endif
	strswitch(pa.ctrlName)
		case "popupType":
			MakeListIntoWaveSelector("BatchRenamerPanel", "listboxSelector", content=pa.popNum, nameFilterProc="BatchRenamer#filterFunc")
			WS_UpdateWaveSelectorWidget("BatchRenamerPanel", "listboxSelector")
			ResetListboxWaves()
			ClearText(1)
			break
	endswitch
	return 0
end

static function WS_NotificationProc(string SelectedItem, variable EventCode)
	if (EventCode==3 && strlen(SelectedItem)) // double click
		STRUCT WMButtonAction s
		s.ctrlName = "buttonSelect"
		s.eventCode = 2
		ButtonFunc(s)
	endif
end

static function ButtonFunc(STRUCT WMButtonAction &s)
	if (s.eventCode != 2)
		return 0
	endif
	
	if (CheckUpdated(s.win, 1))
		return 0
	endif
	
	string cmd = ""
	strswitch(s.ctrlName)
		case "ButtonClear":
			ClearText(1)
			WS_UpdateWaveSelectorWidget("BatchRenamerPanel", "listboxSelector")
			break
		case "buttonSelect":
			selectItems()
			break
		case "buttonDoIt":
			renameItems()
			break
		case "buttonCmd":
			copyCmd(destination="CommandLine")
			break
		case "buttonClip":
			copyCmd(destination="Clip")
			break
		case "buttonHelp":
			help()
			break
		case "buttonCancel":
			KillDataFolder /Z root:Packages:BatchRenamer
			SaveWindowPosition(s.win)
			KillWindow /Z $s.win
			break
	endswitch
	return 0
end

static function copyCmd([string destination])
	destination = SelectString(ParamIsDefault(destination), destination, "CommandLine")
	Notebook BatchRenamerPanel#nbCmd selection={startOfFile,endofFile}
	GetSelection Notebook, BatchRenamerPanel#nbCmd, 2
	Notebook BatchRenamerPanel#nbCmd selection={endofFile,endofFile}
	if(cmpstr(destination,"CommandLine") == 0)
		if(strlen(s_selection)>2500)
			DoAlert 0, "command too long for commandline"
			return 0
		endif
		ToCommandLine s_selection
	else
		PutScrapText s_selection
	endif
end

static function RenameItems()
	STRUCT PackagePrefs prefs
	LoadPrefs(prefs)
	
	string cmd = ""
	Notebook BatchRenamerPanel#nbCmd selection={startOfFile,endofFile}
	GetSelection Notebook, BatchRenamerPanel#nbCmd, 2
	Notebook BatchRenamerPanel#nbCmd selection={endofFile,endofFile}
	int numCmd = ItemsInList(s_selection)
	int i
	for (i=0;i<numCmd;i+=1)
		cmd = TrimString(StringFromList(i, s_selection))
		Execute /Q/Z cmd
		if (v_flag==0 && (prefs.options&1))
			printf "•%s\r", cmd
		endif
	endfor
	WS_UpdateWaveSelectorWidget("BatchRenamerPanel", "listboxSelector")
	DFREF dfr = root:Packages:BatchRenamer
	wave /T/SDFR=dfr wPaths, NamesListWave
	wave sw = dfr:sw
	Redimension /N=(0,-1,-1) wPaths, NamesListWave, sw
	SetDimLabels("\JC≡;CurrentName;NewName;\JC⊗;", 1, NamesListWave)
	SetDimLabels(";backColors;foreColors;", 2, sw)
	SetNewNames()
end

static function SelectItems()
	DFREF dfr = root:Packages:BatchRenamer
	wave /T/SDFR=dfr wPaths, NamesListWave
	wave /SDFR=dfr sw
	STRUCT PanelStatusStructure s
	FillPanelStructure(s)
	string strType = RemoveEnding(s.type.sval, "s")
	wave /T wNew = ListToTextWave(WS_SelectedObjectsList("BatchRenamerPanel", "listboxSelector"),";")
	int i
	int numItems = numpnts(wNew)
	sw[][0][0] = 0
	for(i=0;i<numItems;i++)
		FindValue /TEXT=wNew[i]/TXOP=4 wPaths
		if(V_value > -1)
			continue
		endif
		wPaths[numpnts(wPaths)] = {wNew[i]}
//		other possibilities for fake delete button: ❌❎⊗⨷⦻✘
		if(GrepString(strType, "Wave")) // unquote liberal wavenames
			NamesListWave[DimSize(NamesListWave,0)][] = {{"\JC≡"},{NameOfWave($wNew[i])},{""},{"\JC🅧"}}
		else
			NamesListWave[DimSize(NamesListWave,0)][] = {{"\JC≡"},{unquote(ParseFilePath(0, wNew[i], ":", 1, 0))},{""},{"\JC🅧"}}
		endif
		// select newly added items
		sw[DimSize(sw,0)][][] = {1} // sets first column, first chunk to 1, others to 0.
	endfor
	
	if (cmpstr(s.type.sval, "DataFolders")==0 && DimSize(wPaths, 0))
		SortColumns /A/R keyWaves={wPaths}, sortWaves={wPaths, NamesListWave, sw}
		NamesListWave[][0] = ""
	endif
	
	SetNewNames()
end

static function SetNewNames()

	STRUCT PanelStatusStructure s
	FillPanelStructure(s)
	
	DFREF dfr = root:Packages:BatchRenamer
	wave /T/SDFR=dfr NamesListWave
	int numItems = DimSize(NamesListWave,0)
	if (numItems == 0)
		GenerateCmd()
		return 0
	endif
	variable maxReplace = s.checkMax.value ? 1 : Inf
	
	Make /free/T/N=3 wtext
	
	DebuggerOptions
	variable sav_debug=V_debugOnError
	DebuggerOptions debugOnError=0 // switch this off in case the regex throws an error
	
	int i
	for (i=0;i<numItems;i++)
		wtext = {s.prefix.sval, NamesListWave[i][%CurrentName], s.suffix.sval}
		if (s.wildcards.value)
			wtext[1] = ReplaceStringWC(s.this.sval, wtext[1], s.with.sval)
		elseif (s.regex.value)
			wtext[1] = ReplaceStringRegEx(s.this.sval, wtext[1], s.with.sval)
		else
			wtext[1] = ReplaceString(s.this.sval, wtext[1], s.with.sval, 0, maxReplace)
		endif
		if (s.tokens.value)
			wtext = SubstituteHash(wtext, s.startNum.value+i)
			wtext = SubstituteNote(wtext, s.startNum.value+i)
		endif
		NamesListWave[i][2] = wtext[0] + wtext[1] + wtext[2]
	endfor
	
	DebuggerOptions debugOnError=sav_debug

	GenerateCmd()
end

static function /S SubstituteNote(string strIn, int point)
	string s1, s2, s3
	SplitString /E="(.*){(.*)}(.*)" strIn, s1, s2, s3
	if (strlen(s2))
		wave /T wPaths = root:Packages:BatchRenamer:wPaths
		wave w = $wPaths[point]
		if (WaveExists(w) == 0)
			return ""
		endif
		string key = StringFromList(0,s2,",")
		string keySeparator = StringFromList(1,s2,",")
		string listSeparator = StringFromList(2,s2,",")
		variable matchCase = str2num(StringFromList(3,s2,","))
		keySeparator = SelectString(strlen(keySeparator)>0, ":", subBackslash(keySeparator))
		listSeparator = SelectString(strlen(listSeparator)>0, ";", subBackslash(listSeparator))
		matchCase = numtype(matchCase) == 0 ? matchCase : 0
		return s1 + StringByKey(key, note(w), keySeparator, listSeparator, matchCase) + s3
	endif
	return strIn
end

static function /S SubBackslash(string str)
	str = ReplaceString("\\r", str, "\r")
	str = ReplaceString("\\t", str, "\t")
	str = ReplaceString("\\n", str, "\n")
	str = ReplaceString("\\'", str, "'")
	str = ReplaceString("\\\"", str, "\"")
	str = ReplaceString("\\\\", str, "\\")
	return str
end

static function GenerateCmd()
	DFREF dfr = root:Packages:BatchRenamer
	wave /T/SDFR=dfr wPaths, NamesListWave
	wave /SDFR=dfr sw
	
	STRUCT PanelStatusStructure s
	FillPanelStructure(s)
	
	int i, type
	string cmd = "", strFolder = ""
	int error = 0 // bitwise error code
		
	strswitch(s.type.sval)
		case "DataFolders":
			type = 11
			break
		case "Waves":
			type = 1
			break
		case "Variables":
			type = 3
			break
		case "Strings":
			type = 4
			break
	endswitch
	
	int numItems = DimSize(wPaths,0)
	int renamed = 0
	
	for(i=0;i<numItems;i++)
		if(cmpstr(NamesListWave[i][%CurrentName], NamesListWave[i][%NewName]) == 0)
			sw[i][2][%foreColors] = 0
			sw[i][2][%backColors] = 0
			continue // ignore items whose name will remain unchanged
		elseif(cmpstr(NamesListWave[i][%NewName], CleanupName(NamesListWave[i][%NewName], 0)) == 0)
			sw[i][2][%foreColors] = 4 // green
		else
			sw[i][2][%foreColors] = 2 // blue
		endif
		
		strFolder = ParseFilePath(1, wPaths[i], ":", 1, 0)
		DFREF folder = $strFolder
		if(DataFolderRefStatus(folder) != 1) // shouldn't arrive here
			error = error | 1 // set bit zero
			continue
		endif
		
		// determine whether we will have already renamed any items that match newname
		FindValue /TEXT=NamesListWave[i][%NewName]/TXOP=4/RMD=[0,i][1,1] NamesListWave
		v_value -= DimSize(NamesListWave, 0)
		renamed = (v_value>-1) && (cmpstr(strFolder, ParseFilePath(1, wPaths[v_value], ":", 1, 0))==0)
		
		// check for name conflicts with previous renames
		FindValue /TEXT=NamesListWave[i][%NewName]/TXOP=4/RMD=[0,i][2,2] NamesListWave
		v_value -= 2 * DimSize(NamesListWave, 0)
		int inList = (v_value>-1 && v_value<i)
				
		if (type == 11) // data folder
			
			if ((DataFolderExists(strFolder + ":" + NamesListWave[i][%NewName]) && (!renamed)) || inList )
				error = error | 2 // set bit 1
				sw[i][2][%foreColors] = 1
				sw[i][2][%backColors] = 3
				continue
			endif
			if (CheckName(NamesListWave[i][%NewName], 11) && (!renamed))
				error = error | 4 // set bit 2
				sw[i][2][%foreColors] = 1
				sw[i][2][%backColors] = 3
				continue
			endif
			sw[i][2][%backColors] = 0
			cmd += "RenameDataFolder " + wPaths[i] + " " + PossiblyQuoteName(NamesListWave[i][%NewName]) + "; "
		else
			if ((exists(strFolder + PossiblyQuoteName(NamesListWave[i][%NewName])) && (!renamed)) || inList)
				error = error | 2
				sw[i][2][%foreColors] = 1
				sw[i][2][%backColors] = 3
				continue
			endif
			
			if (CheckName(NamesListWave[i][%NewName], type) && (!renamed))
				error = error | 4
				sw[i][2][%foreColors] = 1
				sw[i][2][%backColors] = 3
				continue
			endif
			sw[i][2][%backColors] = 0
			if(DataFolderRefsEqual(GetDataFolderDFR(), folder))
				cmd += "Rename " + PossiblyQuoteName(NamesListWave[i][%CurrentName]) + " " + PossiblyQuoteName(NamesListWave[i][%NewName]) + "; "
			else
				cmd += "Rename " + wPaths[i] + " " + PossiblyQuoteName(NamesListWave[i][%NewName]) + "; "
			endif
		endif
	endfor
	cmd = RemoveEnding(cmd, "; ")
	if (error)
		cmd = ""
		if (error & 1)
			cmd += "** data folder does not exist **\r"
		endif
		if (error & 2)
			cmd += "** name conflict **\r"
		endif
		if (error & 4)
			cmd += "** illegal name **\r"
		endif
		cmd = RemoveEnding(cmd, "\r")
	endif
	
	Notebook BatchRenamerPanel#nbCmd selection={startOfFile,endofFile}
	Notebook BatchRenamerPanel#nbCmd text=cmd
	Notebook BatchRenamerPanel#nbCmd selection={endofFile,endofFile}
	
	int disableButtons = 2*(GrepString(cmd, "^\*"))
	Button buttonCmd, win=BatchRenamerPanel, disable=disableButtons
	Button buttonDoIt, win=BatchRenamerPanel, disable=disableButtons
	Button buttonClip, win=BatchRenamerPanel, disable=disableButtons
end

static function SetDimLabels(string strList, int dim, wave w)
	int numLabels = ItemsInList(strList)
	if (numLabels != DimSize(w, dim))
		return 0
	endif
	int i
	for (i=0;i<numLabels;i+=1)
		SetDimLabel dim, i, $StringFromList(i, strList), w
	endfor
	return 1
end

static function /S unquote(string s)
	int len = strlen(s)
	if (cmpstr(s[0] + s[len-1], "''") == 0)
		return s[1,len-2]
	endif
	return s
end

static function help()
	string cmd = "  Batch Renamer [version " + num2str(ProcedureVersion("")) + "];"
	cmd += "Use this dialog to rename waves, variables, strings, and data folders.;"
	cmd += "Select the type of object to be renamed in the popup menu.;"
	cmd += "Use the arrow button to transfer selected items to the list on the right side of the dialog.;"
	cmd += "Edit the Prefix, Suffix and Replace Text fields to generate new object names.;"
	cmd += "Check '1 time' to replace only the first instance in each item.;"
	cmd += "Changed names are indicated by blue text for liberal names and green for non-liberal.;"
	cmd += "Double-click to transfer an item from the browser to the rename list.;"
	cmd += "Press Delete or Backspace to remove selected rows from the rename list.;"
	cmd += "Click the column title or click ≡ and drag to reorder items in the rename list.;"
	cmd += "In the 'prefix', 'suffix' and 'replace with' fields, # represents a number.;"
	cmd += "Use multiple # characters to set minimum number of digits. To insert a string by key;"
	cmd += "from a wavenote, use the syntax {key[,keySepStr[,listSepStr[,matchCase]]]};"	
	PopupContextualMenu cmd
end

// function used by WaveSelectorWidget
static function FilterFunc(string aName, variable contents)
	DFREF dfr = root:Packages:BatchRenamer
	SVAR strFilter = dfr:strFilter
	string leafName = ParseFilePath(0, aName, ":", 1, 0)
	int vFilter = 0
	try
		vFilter = GrepString(leafName, "(?i)" + strFilter); AbortOnRTE
	catch
		int err = GetRTError(1)
	endtry
	return vFilter
end

static function ClearText(int doIt)
	if(doIt) // clear filter widget
		Notebook BatchRenamerPanel#nbFilter selection={startOfFile,endofFile}, textRGB=(50000,50000,50000), text="Filter"
		Notebook BatchRenamerPanel#nbFilter selection={startOfFile,startOfFile}
		Button buttonClear, win=BatchRenamerPanel, disable=3
		SVAR strFilter = root:Packages:BatchRenamer:strFilter
		strFilter = ""
	endif
end

// intercept and deal with keyboard events in notebook subwindow
// also deal with killing or resizing panel
static function FilterHook(STRUCT WMWinHookStruct &s)
	
	if (s.eventcode == 4) // mousemoved
		return 0
	endif
	
	if (s.eventcode == 2) // window is being killed
		KillDataFolder /Z root:Packages:BatchRenamer
		SaveWindowPosition(s.WinName)
		return 1
	endif
	
	if (s.eventcode == 6) // resize
		GetWindow BatchRenamerPanel wsize // $s.winName is unreliable in Igor8
		Notebook BatchRenamerPanel#nbCmd margins={0,0,435+(V_right-V_left)-470}
		Notebook BatchRenamerPanel#nbCmd selection={startOfFile,startOfFile}, findText={"",1}
	endif
		
	GetWindow /Z BatchRenamerPanel activeSW
	if (cmpstr(s_value, "BatchRenamerPanel#nbFilter"))
		return 0
	endif
	
	if(s.eventCode == 22 && cmpstr(s.WinName, "BatchRenamerPanel#nbFilter")==0) // don't allow scrolling
		return 1
	endif
	
	DFREF dfr = root:Packages:BatchRenamer
	SVAR strFilter = dfr:strFilter
	int vLength = strlen(strFilter)
	
	if(s.eventcode==3 && vLength==0) // mousedown
		return 1 // don't allow mousedown when we have 'filter' displayed in nb
	endif
		
	if (s.eventcode == 10) // menu
		strswitch(s.menuItem)
			case "Paste":
				string strScrap = GetScrapText()
				strScrap = ReplaceString("\r", strScrap, "")
				strScrap = ReplaceString("\n", strScrap, "")
				strScrap = ReplaceString("\t", strScrap, "")
				
				GetSelection Notebook, BatchRenamerPanel#nbFilter, 1 // get current position in notebook
				if(vLength == 0)
					Notebook BatchRenamerPanel#nbFilter selection={startOfFile,endofFile}, text=strScrap
				else
					Notebook BatchRenamerPanel#nbFilter selection={(0,V_startPos),(0,V_endPos)}, text=strScrap
				endif
				vLength += strlen(strScrap) - abs(V_endPos - V_startPos)
				s.eventcode = 11
				// pretend this was a keyboard event to allow execution to continue
				break
			case "Cut":
				GetSelection Notebook, BatchRenamerPanel#nbFilter, 3 // get current position in notebook
				PutScrapText s_selection
				Notebook BatchRenamerPanel#nbFilter selection={(0,V_startPos),(0,V_endPos)}, text=""
				vLength -= strlen(s_selection)
				s.eventcode = 11
				break
			case "Clear":
				GetSelection Notebook, BatchRenamerPanel#nbFilter, 3 // get current position in notebook
				Notebook BatchRenamerPanel#nbFilter selection={(0,V_startPos),(0,V_endPos)}, text="" // clear text
				vLength -= strlen(s_selection)
				s.eventcode = 11
				break
		endswitch
		Button buttonClear, win=BatchRenamerPanel, disable=3*(vLength == 0)
		ClearText((vLength == 0))
	endif
				
	if (s.eventcode!=11)
		return 0
	endif
	
	if (vLength == 0) // Remove "Filter" text before starting to deal with keyboard activity
		Notebook BatchRenamerPanel#nbFilter selection={startOfFile,endofFile}, text=""
	endif
	
	// deal with some non-printing characters
	switch (s.keycode)
		case 9:	// tab: jump to end
		case 3:
		case 13: // enter or return: jump to end
			Notebook BatchRenamerPanel#nbFilter selection={endOfFile,endofFile}
			break
		case 28: // left arrow
		case 29: // right arrow
			ClearText((vLength == 0)); return (vLength == 0)
		case 8:
		case 127: // delete or forward delete
			GetSelection Notebook, BatchRenamerPanel#nbFilter, 1
			if(V_startPos == V_endPos)
				V_startPos -= (s.keycode == 8)
				V_endPos += (s.keycode == 127)
			endif
			V_startPos = min(vLength,V_startPos); V_endPos = min(vLength,V_endPos)
			V_startPos = max(0, V_startPos); V_endPos = max(0, V_endPos)
			Notebook BatchRenamerPanel#nbFilter selection={(0,V_startPos),(0,V_endPos)}, text=""
			vLength -= abs(V_endPos - V_startPos)
			break
	endswitch
		
	// find and save current position
	GetSelection Notebook, BatchRenamerPanel#nbFilter, 1
	int selEnd = V_endPos
		
	if (strlen(s.keyText) == 1) // a one-byte printing character
		// insert character into current selection
		Notebook BatchRenamerPanel#nbFilter text=s.keyText, textRGB=(0,0,0)
		vLength += 1 - abs(V_endPos - V_startPos)
		// find out where we want to leave cursor
		GetSelection Notebook, BatchRenamerPanel#nbFilter, 1
		selEnd = V_endPos
	endif
	
	// select and format text
	Notebook BatchRenamerPanel#nbFilter selection={startOfFile,endOfFile}, textRGB=(0,0,0)
	// put text into global filter string
	GetSelection Notebook, BatchRenamerPanel#nbFilter, 3
	strFilter = s_selection
	Notebook BatchRenamerPanel#nbFilter selection={(0,selEnd),(0,selEnd)}, findText={"",1}
	
	Button buttonClear, win=BatchRenamerPanel, disable=3*(vLength==0)
	ClearText((vLength == 0))
	
	WS_UpdateWaveSelectorWidget("BatchRenamerPanel", "listboxSelector")
	
	return 1 // tell Igor we've handled all keyboard events
end

// PNG: width= 90, height= 30
static Picture ClearTextPicture
	ASCII85Begin
	M,6r;%14!\!!!!.8Ou6I!!!"&!!!!?#R18/!3BT8GQ7^D&TgHDFAm*iFE_/6AH5;7DfQssEc39jTBQ
	=U"$&q@5u_NKm@(_/W^%DU?TFO*%Pm('G1+?)0-OWfgsSqYDhC]>ST`Z)0"D)K8@Ncp@>C,GnA#([A
	Jb0q`hu`4_P;#bpi`?T]j@medQ0%eKjbh8pO.^'LcCD,L*6P)3#odh%+r"J\$n:)LVlTrTIOm/oL'r
	#E&ce=k6Fiu8aXm1/:;hm?p#L^qI6J;D8?ZBMB_D14&ANkg9GMLR*Xs"/?@4VWUdJ,1MBB0[bECn33
	KZ1__A<"/u9(o<Sf@<$^stNom5GmA@5SIJ$^\D=(p8G;&!HNh)6lgYLfW6>#jE3aT_'W?L>Xr73'A#
	m<7:2<I)2%%Jk$'i-7@>Ml+rPk4?-&B7ph6*MjH9&DV+Uo=D(4f6)f(Z9"SdCXSlj^V?0?8][X1#pG
	[0-Dbk^rVg[Rc^PBH/8U_8QFCWdi&3#DT?k^_gU>S_]F^9g'7.>5F'hcYV%X?$[g4KPRF0=NW^$Z(L
	G'1aoAKLpqS!ei0kB29iHZJgJ(_`LbUX%/C@J6!+"mVIs6V)A,gbdt$K*g_X+Um(2\?XI=m'*tR%i"
	,kQIh51]UETI+HBA)DV:t/sl4<N*#^^=N.<B%00/$P>lNVlic"'Jc$p^ou^SLA\BS?`$Jla/$38;!#
	Q+K;T6T_?\3*d?$+27Ri'PYY-u]-gEMR^<d.ElNUY$#A@tX-ULd\IU&bfX]^T)a;<u7HgR!i2]GBpt
	SiZ1;JHl$jf3!k*jJlX$(ZroR:&!&8D[<-`g,)N96+6gSFVi$$Gr%h:1ioG%bZgmgbcp;2_&rF/[l"
	Qr^V@O-"j&UsEk)HgI'9`W31Wh"3^O,KrI/W'chm_@T!!^1"Y*Hknod`FiW&N@PIluYQdKILa)RK=W
	Ub4(Y)ao_5hG\K-+^73&AnBNQ+'D,6!KY/`F@6)`,V<qS#*-t?,F98]@h"8Y7Kj.%``Q=h4.L(m=Nd
	,%6Vs`ptRkJNBdbpk]$\>hR4"[5SF8$^:q=W([+TB`,%?4h7'ET[Y6F!KJ3fH"9BpILuUI#GoI.rl(
	_DAn[OiS_GkcL7QT`\p%Sos;F.W#_'g]3!!!!j78?7R6=>B
	ASCII85End
end

static function /S ReplaceStringWC(string replaceThisStr, string inStr, string withThisStr)
	string s1 = "", s2 = ""
	string regex = replaceThisStr
	regex = ReplaceString(".", regex, "\.")
	regex = ReplaceString("?", regex, ".")
	regex = ReplaceString("*", regex, ".*")
	regex = "((?i)" + regex + ")"
	try
		variable grepWorks = GrepString(inStr, regex); AbortOnRTE
		if (grepWorks)
			regex[0,0] = "(^"
			regex += "(.*)"
			int i
			for (i=0;i<strlen(inStr);i++)
				SplitString /E=regex inStr[i,Inf], s1, s2
				if (strlen(s1))
					return inStr[0,i-1] + withThisStr + s2
				endif
			endfor
		endif
	catch
		variable CFerror = GetRTError(1) // 1 to clear the error
	endtry
	return inStr
end

static function /S ReplaceStringRegEx(string replaceThisStr, string inStr, string withThisStr)
	try
		variable grepWorks = GrepString(inStr, replaceThisStr); AbortOnRTE
		if (grepWorks)
			string s1 = "", s2 = ""
			string regex = "(^" + replaceThisStr + ")(.*)"
			int i
			for (i=0;i<strlen(inStr);i++)
				SplitString /E=regex inStr[i,Inf], s1, s2
				if (strlen(s1))
					return inStr[0,i-1] + withThisStr + s2
				endif
			endfor
		endif
	catch
		variable CFerror = GetRTError(1) // 1 to clear the error
	endtry
	return inStr
end

static function /S SubstituteHash(string strSuf, int value)
	int i, j
	i = strsearch(strSuf, "#", 0)
	if (i > -1)
		for(j=i+1;cmpstr(strSuf[j],"#")==0 && j<strlen(strSuf);j++)
		endfor
		sprintf strSuf, "%s%*.*d%s", strSuf[0,i-1], j-i, j-i, value, strSuf[j,Inf]
	endif
	return strSuf
end

static function DragReorder(STRUCT WMListboxAction &lba)
	 
	if (lba.eventCode == 2) // mouseup
		ListBox $lba.ctrlName, win=$lba.win, userdata(drag)=""
	endif

	if (lba.eventCode==1 && lba.col==0 && lba.row>-1 && lba.row<DimSize(lba.listwave,0) && strlen(lba.listwave[lba.row][0])) // mousedown
		ListBox $lba.ctrlName, win=$lba.win, userdata(drag)=num2str(lba.row)
		// userdata(drag) indicates dragging is active, cleared on mouseup
		lba.selwave[][0][0] = (p == lba.row)
		// select only one row
	endif
			 
	if (lba.eventCode==4) // selection of lba.row
		variable dragNum=str2num(GetUserData(lba.win,lba.ctrlName,"drag"))
		if(numtype(dragNum)!=0 || min(dragNum,lba.row)<0 || max(dragNum,lba.row)>=DimSize(lba.listwave,0))
			return 0
		endif
		wave /T wPaths = root:Packages:BatchRenamer:wPaths
		Make /free/N=(DimSize(lba.selwave, 0)) order
		order = (p == dragNum) ? lba.row - 0.5 + (lba.row > dragNum) : x
		SortColumns keywaves={order}, sortwaves={lba.listwave, wPaths}
		ListBox $lba.ctrlName, win=$lba.win, userdata(drag)=num2str(lba.row)
		SetNewNames()
	endif
end

// returns truth that this procedure file has been updated since initialisation
static function CheckUpdated(string win, int restart)	
	if (cmpstr(GetUserData(win, "", "version"), num2str(ProcedureVersion(""))))
		if (restart)
			DoAlert 0, "You have updated the package since this panel was created.\r\rThe package will restart to update the control panel."
			MakeBatchRenamerPanel()
		else
			DoAlert 0, "You have updated the package since this panel was created.\r\rPlease close and reopen the panel to continue."
		endif
		return 1
	endif
	return 0
end

// note that neither built-in ProcedureVersion("") nor this function work
// for independent modules!
#if (exists("ProcedureVersion") != 3)
// replicates ProcedureVersion function for older versions of Igor
static function ProcedureVersion(string win)
	variable noversion = 0 // default value when no version is found
	if (strlen(win) == 0)
		string strStack = GetRTStackInfo(3)
		win = StringFromList(ItemsInList(strStack, ",") - 2, strStack, ",")
		string IM = " [" + GetIndependentModuleName() + "]"
	endif
	
	wave /T ProcText = ListToTextWave(ProcedureText("", 0, win + IM), "\r")	
	
	variable version
	Grep /Q/E="(?i)^#pragma[\s]*version[\s]*=" /LIST/Z ProcText
	s_value = LowerStr(TrimString(s_value, 1))
	sscanf s_value, "#pragma version = %f", version

	if (V_flag!=1 || version<=0)
		return noversion
	endif
	return version	
end
#endif
