#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3
#pragma DefaultTab={3,20,4}
#pragma ModuleName=BatchRenamer
#pragma version=1.2Í

#include <WaveSelectorWidget>

static constant kTesting=1

strconstant ksPackageName=BatchRenamer
strconstant ksPrefsFileName=acwBatchRenamer.bin
constant kPrefsVersion=100

// to do
// create help
// an option to hide the packages folder in the wave selector widget would be nice!

menu "Data"
	submenu "Packages"
		"Batch Rename...",/Q, BatchRenamer#BatchRename()
	end
end

// ------------------ package preferences --------------------

static Structure PackagePrefs
	uint32 version
	STRUCT Rect win // window position and size, 8 bytes
	char reserved[128-4-8]
EndStructure

// set prefs structure to default values
static function PrefsSetDefaults(STRUCT PackagePrefs &prefs)		
	prefs.version=kPrefsVersion
	prefs.win.left=20
	prefs.win.top=20
	prefs.win.right=20+470
	prefs.win.bottom=20+340	
	int i
	for(i=0;i<(128-12);i+=1)
		prefs.reserved[i]=0
	endfor
end

static function LoadPrefs(STRUCT PackagePrefs &prefs)	
	LoadPackagePreferences ksPackageName, ksPrefsFileName, 0, prefs
	if (V_flag!=0 || V_bytesRead==0 || prefs.version!=kPrefsVersion)
		PrefsSetDefaults(prefs)
	endif
end

// save window position in package prefs
static function SaveWindowPosition(string strWin)
	
	STRUCT PackagePrefs prefs
	LoadPrefs(prefs)
	
	string recreation=WinRecreation(strWin, 0)
	variable index, top, left, bottom, right
	// save window position
	index=strsearch(recreation, "/W=(", 0)
	if (index>0)
		sscanf recreation[index,strlen(recreation)-1], "/W=(%g,%g,%g,%g)", left, top, right, bottom
		prefs.win.top=top
		prefs.win.left=left
		prefs.win.bottom=bottom
		prefs.win.right=right
	endif
	
	SavePackagePreferences ksPackageName, ksPrefsFileName, 0, prefs
end

function BatchRename()

	DoWindow /K BatchRenamerPanel
	
	// load package preferences
	STRUCT PackagePrefs prefs
	LoadPrefs(prefs)
	
	// create package data folder
	NewDataFolder /O root:Packages
	NewDataFolder /O root:Packages:BatchRenamer
	DFREF dfr = root:Packages:BatchRenamer
	string /G dfr:strFilter=""
	Make /O/N=0/T dfr:wPaths
	Make /O/N=(0,4)/T dfr:renamelistwave /wave=renamelistwave
	setDimLabels("Current;Type;NewName;\JC⊗;", 1, renamelistwave)
	
	Make/O/B/U/N=(0,4,3) dfr:sw /wave=sw
	SetDimLabel 2, 1, backColors, sw
	SetDimLabel 2, 2, foreColors, sw
	make/n=(2,3)/O/W/U dfr:wcolor /wave=wcolor
	wcolor[1][]={{65535},{0},{0}} // red
	wcolor[2][]={{0},{0},{65535}} // blue
	wcolor[3][]={{65535},{60000},{60000}} // pink
	
	NewPanel /K=1/N=BatchRenamerPanel/W=(prefs.win.left,prefs.win.top,prefs.win.left+470,prefs.win.top+340) as "Batch Renamer"
	
	DefineGuide/W=BatchRenamerPanel FGc={FL,0.5,FR}
	DefineGuide/W=BatchRenamerPanel cmdR={FR,-10}
	DefineGuide/W=BatchRenamerPanel cmdT={FT,0.75,FB}
	DefineGuide/W=BatchRenamerPanel cmdB={FB,-40}
	NewNotebook /F=1 /N=nbCmd /HOST=BatchRenamerPanel /W=(10,10,190,35)/FG=($"",cmdT,cmdR,cmdB) /OPTS=11
	Notebook BatchRenamerPanel#nbCmd fSize=12, showRuler=0
	Notebook BatchRenamerPanel#nbCmd spacing={4,0,5},changeableByCommandOnly=1
	Notebook BatchRenamerPanel#nbCmd margins={0,0,435}, backRGB=(60066,60076,60063)
	SetWindow BatchRenamerPanel#nbCmd, activeChildFrame=0
	SetActiveSubwindow BatchRenamerPanel

	// insert a notebook subwindow to be used for filtering lists
	DefineGuide/W=BatchRenamerPanel fgb={cmdT,-5}
	DefineGuide/W=BatchRenamerPanel fgt={cmdT,-22}
	DefineGuide/W=BatchRenamerPanel fgr={FGc,-82}
	NewNotebook /F=1 /N=nbFilter /HOST=BatchRenamerPanel /W=(10,500,5200,1000)/FG=($"",fgt,fgr,fgb) /OPTS=3
	Notebook BatchRenamerPanel#nbFilter showRuler=0
	Notebook BatchRenamerPanel#nbFilter spacing={1, 0, 0}
	Notebook BatchRenamerPanel#nbFilter margins={0,0,1000}
	SetWindow BatchRenamerPanel#nbFilter, activeChildFrame=0
	ClearText(1) // sets notebook to its default appearance
	SetActiveSubwindow BatchRenamerPanel
	
	// make a Button for clearing text in notebook subwindow
	Button ButtonClear, win=BatchRenamerPanel,pos={155,234},size={15,15},title=""
	Button ButtonClear, win=BatchRenamerPanel, Picture=BatchRenamer#ClearTextPicture,Proc=BatchRenamer#ButtonFunc, disable=1
	
	PopupMenu popupType, win=BatchRenamerPanel, pos={10, 5}, value="Waves;Variables;Strings;DataFolders;"
	PopupMenu popupType, win=BatchRenamerPanel, Proc=BatchRenamer#PopMenuFunc

	CheckBox checkPre,pos={250,8},size={15,15},title="",value=0,mode=0, Proc=BatchRenamer#CheckFunc
	CheckBox checkSuf,pos={360,8},size={15,15},title="",value=0,mode=0, Proc=BatchRenamer#CheckFunc
	SetVariable setvarPrefix, win=BatchRenamerPanel, pos={270,10}, size={70,14}, title="Prefix:"
	SetVariable setvarPrefix, win=BatchRenamerPanel, value=_STR:"pre_", Proc=BatchRenamer#SetVarFunc, focusRing=0
	SetVariable setvarSuffix, win=BatchRenamerPanel, pos={380,10}, size={70,14}, title="Suffix:"
	SetVariable setvarSuffix, win=BatchRenamerPanel, value=_STR:"_suf", Proc=BatchRenamer#SetVarFunc, focusRing=0
	SetVariable setvarThis, win=BatchRenamerPanel, pos={270,30}, size={90,14}, title="Replace"
	SetVariable setvarThis, win=BatchRenamerPanel, value=_STR:"", Proc=BatchRenamer#SetVarFunc, focusRing=0
	SetVariable setvarWith, win=BatchRenamerPanel, pos={365,30}, size={80,14}, title="with"
	SetVariable setvarWith, win=BatchRenamerPanel, value=_STR:"", Proc=BatchRenamer#SetVarFunc, focusRing=0
	
	ListBox listboxSelector, win=BatchRenamerPanel, pos={10,30}, size={160,200}, focusRing=0
	MakeListIntoWaveSelector("BatchRenamerPanel", "listboxSelector", content=WMWS_Waves, nameFilterProc="BatchRenamer#filterFunc")
	
	ListBox listboxRenamer, win=BatchRenamerPanel, pos={240,50}, size={220,200}, focusRing=0, listWave=renamelistwave, widths={10,5,10,3}
	ListBox listboxRenamer, win=BatchRenamerPanel, Proc=BatchRenamer#ListboxFunc, selwave=dfr:sw, colorWave=wcolor
	
	Button buttonSelect, win=BatchRenamerPanel,pos={180,100},size={50,20},fsize=14, title="→", valueColor=(0,0,65535), fstyle=1
	Button buttonSelect, win=BatchRenamerPanel, Proc=BatchRenamer#ButtonFunc
	Button buttonDoIt, win=BatchRenamerPanel,pos={15,313},size={55,20},fsize=14, title="Do It"
	Button buttonDoIt, win=BatchRenamerPanel, Proc=BatchRenamer#ButtonFunc, disable=2
	Button buttonCmd, win=BatchRenamerPanel,pos={90,313},size={105,20},fsize=14, title="To Cmd Line"
	Button buttonCmd, win=BatchRenamerPanel, Proc=BatchRenamer#ButtonFunc, disable=2
	Button buttonClip, win=BatchRenamerPanel,pos={215,313},size={75,20},fsize=14, title="To Clip"
	Button buttonClip, win=BatchRenamerPanel, Proc=BatchRenamer#ButtonFunc, disable=2
	Button buttonHelp, win=BatchRenamerPanel,pos={310,313},size={60,20},fsize=14, title="Help"
	Button buttonHelp, win=BatchRenamerPanel, Proc=BatchRenamer#ButtonFunc, disable=2
	Button buttonCancel, win=BatchRenamerPanel,pos={390,313},size={65,20},fsize=14, title="Cancel"
	Button buttonCancel, win=BatchRenamerPanel, Proc=BatchRenamer#ButtonFunc
	
	SetWindow BatchRenamerPanel hook(hFilterHook)=BatchRenamer#FilterHook
	
	// resizing userdata for controls
	Button buttonClear,userdata(ResizeControlsInfo)= A"!!,G+!!#B$!!#<(!!#<(z!!#N3Bk1ct7Rpqgzzzzzzzzzzzzz!!#N3Bk1ct7Rpqgz"
	Button buttonClear,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#N3Bk1ct@r5aUzzzzzzzzzz"
	Button buttonClear,userdata(ResizeControlsInfo) += A"zzz!!#N3Bk1ct@r5aUzzzzzzzzzzzzz!!!"
	PopupMenu popupType,userdata(ResizeControlsInfo)= A"!!,A.!!#9W!!#?K!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	PopupMenu popupType,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu popupType,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox checkPre,userdata(ResizeControlsInfo)= A"!!,H5!!#:b!!#<(!!#<8z!!#o2B4uAezzzzzzzzzzzzzz!!#o2B4uAezz"
	CheckBox checkPre,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox checkPre,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox checkSuf,userdata(ResizeControlsInfo)= A"!!,Ho!!#:b!!#<(!!#<8z!!#o2B4uAezzzzzzzzzzzzzz!!#o2B4uAezz"
	CheckBox checkSuf,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox checkSuf,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvarPrefix,userdata(ResizeControlsInfo)= A"!!,HB!!#;-!!#?E!!#;mz!!#o2B4uAezzzzzzzzzzzzzz!!#o2B4uAezz"
	SetVariable setvarPrefix,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvarPrefix,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvarSuffix,userdata(ResizeControlsInfo)= A"!!,I$!!#;-!!#?E!!#;mz!!#o2B4uAezzzzzzzzzzzzzz!!#o2B4uAezz"
	SetVariable setvarSuffix,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvarSuffix,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvarThis,userdata(ResizeControlsInfo)= A"!!,HB!!#=S!!#?m!!#;mz!!#o2B4uAezzzzzzzzzzzzzz!!#o2B4uAezz"
	SetVariable setvarThis,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvarThis,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	SetVariable setvarWith,userdata(ResizeControlsInfo)= A"!!,HqJ,hn)!!#?Y!!#;mz!!#o2B4uAezzzzzzzzzzzzzz!!#o2B4uAezz"
	SetVariable setvarWith,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	SetVariable setvarWith,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	ListBox listboxSelector,userdata(ResizeControlsInfo)= A"!!,A.!!#=S!!#A/!!#AWz!!#](Aon\"Qzzzzzzzzzzzzzz!!#N3Bk1ct7Rpqgz"
	ListBox listboxSelector,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	ListBox listboxSelector,userdata(ResizeControlsInfo) += A"zzz!!#N3Bk1ct@r5aUzzzzzzzzzzzzz!!!"
	ListBox listboxRenamer,userdata(ResizeControlsInfo)= A"!!,H+!!#>V!!#Ak!!#AWz!!#N3Bk1ct7Rpqgzzzzzzzzzzzzz!!#o2B4uAezz"
	ListBox listboxRenamer,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	ListBox listboxRenamer,userdata(ResizeControlsInfo) += A"zzz!!#N3Bk1ct@r5aUzzzzzzzzzzzzz!!!"
	Button buttonSelect,userdata(ResizeControlsInfo)= A"!!,GD!!#@,!!#>V!!#<Xz!!#N3Bk1ct7Rpqgzzzzzzzzzzzzz!!#N3Bk1ct7Rpqgz"
	Button buttonSelect,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!\";f87cLJBQO5Rzzzzzzzzzz"
	Button buttonSelect,userdata(ResizeControlsInfo) += A"zzz!!#r+D.Oh\\ASGdjF8u:@zzzzzzzzzzzz!!!"
	Button buttonDoIt,userdata(ResizeControlsInfo)= A"!!,B)!!#BVJ,ho@!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button buttonDoIt,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	Button buttonDoIt,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	Button buttonCmd,userdata(ResizeControlsInfo)= A"!!,En!!#BVJ,hpa!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button buttonCmd,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	Button buttonCmd,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	Button buttonClip,userdata(ResizeControlsInfo)= A"!!,Gg!!#BVJ,hp%!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button buttonClip,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	Button buttonClip,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	Button buttonHelp,userdata(ResizeControlsInfo)= A"!!,HV!!#BVJ,hoT!!#<Xz!!#o2B4uAezzzzzzzzzzzzzz!!#o2B4uAezz"
	Button buttonHelp,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	Button buttonHelp,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	Button buttonCancel,userdata(ResizeControlsInfo)= A"!!,I)!!#BVJ,hof!!#<Xz!!#o2B4uAezzzzzzzzzzzzzz!!#o2B4uAezz"
	Button buttonCancel,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
	Button buttonCancel,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	
	// resizing userdata for panel
	SetWindow kwTopWin,userdata(ResizeControlsInfo)= A"!!*'\"z!!#CP!!#Bdzzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzzzzzzzzz!!!"
	SetWindow kwTopWin,userdata(ResizeControlsGuides)=  "FGc;cmdR;cmdT;cmdB;fgb;fgt;fgr;"
	SetWindow kwTopWin,userdata(ResizeControlsInfoFGc)=  "NAME:FGc;WIN:BatchRenamerPanel;TYPE:User;HORIZONTAL:0;POSITION:235.00;GUIDE1:FL;GUIDE2:FR;RELPOSITION:0.5;"
	SetWindow kwTopWin,userdata(ResizeControlsInfocmdR)=  "NAME:cmdR;WIN:BatchRenamerPanel;TYPE:User;HORIZONTAL:0;POSITION:460.00;GUIDE1:FR;GUIDE2:;RELPOSITION:-10;"
	SetWindow kwTopWin,userdata(ResizeControlsInfocmdT)=  "NAME:cmdT;WIN:BatchRenamerPanel;TYPE:User;HORIZONTAL:1;POSITION:255.00;GUIDE1:FT;GUIDE2:FB;RELPOSITION:0.75;"
	SetWindow kwTopWin,userdata(ResizeControlsInfocmdB)=  "NAME:cmdB;WIN:BatchRenamerPanel;TYPE:User;HORIZONTAL:1;POSITION:300.00;GUIDE1:FB;GUIDE2:;RELPOSITION:-40;"
	SetWindow kwTopWin,userdata(ResizeControlsInfofgb)=  "NAME:fgb;WIN:BatchRenamerPanel;TYPE:User;HORIZONTAL:1;POSITION:250.00;GUIDE1:cmdT;GUIDE2:;RELPOSITION:-5;"
	SetWindow kwTopWin,userdata(ResizeControlsInfofgt)=  "NAME:fgt;WIN:BatchRenamerPanel;TYPE:User;HORIZONTAL:1;POSITION:233.00;GUIDE1:cmdT;GUIDE2:;RELPOSITION:-22;"
	SetWindow kwTopWin,userdata(ResizeControlsInfofgr)=  "NAME:fgr;WIN:BatchRenamerPanel;TYPE:User;HORIZONTAL:0;POSITION:153.00;GUIDE1:FGc;GUIDE2:;RELPOSITION:-82;"

	// resizing panel hook
	SetWindow BatchRenamerPanel hook(ResizeControls)=ResizeControls#ResizeControlsHook
	
	// resize to restore window size
	MoveWindow /W=BatchRenamerPanel prefs.win.left,prefs.win.top,prefs.win.right,prefs.win.bottom
	
	if(!kTesting)
		PauseForUser BatchRenamerPanel
	endif
end


static function ValidCell(STRUCT WMListboxAction &s)
	return s.row>-1 && s.col>-1 && s.row<dimsize(s.listWave, 0) && s.col<dimsize(s.listWave, 1)
end

// this function enables the deleterow 'button'
static function ListboxFunc(STRUCT WMListboxAction &s)
	
	if(s.eventCode==1 && s.col==3) // mousedown
		if(ValidCell(s)==0)
			return 0
		endif
		ListBox $s.ctrlName, win=$s.win, userdata(mousedownrow)=num2str(s.row)
		s.selwave[s.row][s.col][%backColors]=2
		DoUpdate /W=$s.win
		int buttondown
		do
			GetMouse /W=$s.win
			buttondown=V_flag&1
		while(buttondown)
		// reset color here, in case mouse is not over same cell for mouseup
		s.selwave[s.row][s.col][%backColors]=0
	endif
		
	if(s.eventCode==2 && s.col==3 && s.row>-1 && s.row<DimSize(s.listWave,0)) // mouseup
		int mousedownrow=str2num(GetUserData(s.win,s.ctrlName,"mousedownrow"))
		if(s.row!=mousedownrow)
			return 0
		endif
		wave /T wPaths=root:Packages:BatchRenamer:wPaths
		wave sw=root:Packages:BatchRenamer:sw
		DeletePoints /M=0 s.row, 1, wPaths, s.listWave, sw
		if(DimSize(s.listWave,0)==0) // when the last row is deleted the wave becomes 1D
			Redimension /N=(0,4) s.listWave
			setDimLabels("Current;Type;NewName;\JC⊗;", 1, s.listWave)
			Redimension /N=(0,4,3) sw
			SetDimLabel 2, 1, backColors, sw
			SetDimLabel 2, 2, foreColors, sw
		endif
		generateCmd()
	endif
	
	if(s.eventCode==2)
		ListBox $s.ctrlName, win=$s.win, userdata(mousedownrow)=""
	endif	
end
	
static function CheckFunc(STRUCT WMCheckboxAction &s)
	if(s.eventcode==2)
		setNewNames()
	endif
	return 0
end

static function SetVarFunc(STRUCT WMSetVariableAction &s)
	if(s.eventcode==8)
		setNewNames()
	endif
	return 0
end

static function PopMenuFunc(STRUCT WMPopupAction &pa)
	if(pa.eventCode==2)
		MakeListIntoWaveSelector("BatchRenamerPanel", "listboxSelector", content=pa.popNum, nameFilterProc="BatchRenamer#filterFunc")
		WS_UpdateWaveSelectorWidget("BatchRenamerPanel", "listboxSelector")
	endif
	return 0
end

static function ButtonFunc(STRUCT WMButtonAction &s)
	if(s.eventCode!=2)
		return 0
	endif
	string cmd=""
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
			
			break
		case "buttonCancel":
			KillWindow /Z $s.win
			break
	endswitch
	return 0
end

static function copyCmd([string destination])
	destination=selectstring(paramisDefault(destination), destination, "CommandLine")
	Notebook BatchRenamerPanel#nbCmd selection={startOfFile,endofFile}
	GetSelection Notebook, BatchRenamerPanel#nbCmd, 2
	Notebook BatchRenamerPanel#nbCmd selection={endofFile,endofFile}
	if(cmpstr(destination,"CommandLine") == 0)
		if(strlen(s_selection)>2500)
			doalert 0, "command too long for commandline"
			return 0
		endif
		ToCommandLine s_selection
	else
		PutScrapText s_selection
	endif
end

static function renameItems()
	string cmd=""
	Notebook BatchRenamerPanel#nbCmd selection={startOfFile,endofFile}
	GetSelection Notebook, BatchRenamerPanel#nbCmd, 2
	Notebook BatchRenamerPanel#nbCmd selection={endofFile,endofFile}
	int numCmd=ItemsInList(s_selection)
	int i
	for (i=0;i<numCmd;i+=1)
		cmd=TrimString(StringFromList(i, s_selection))
		Print cmd
		Execute cmd
	endfor
	WS_UpdateWaveSelectorWidget("BatchRenamerPanel", "listboxSelector")
	DFREF dfr = root:Packages:BatchRenamer
	wave /T/SDFR=dfr wPaths, renamelistwave
	Redimension /N=(0,-1) wPaths, renamelistwave
	setDimLabels("Current;Type;NewName;\JC⊗;", 1, renamelistwave)
	setNewNames()
end

static function selectItems()
	DFREF dfr = root:Packages:BatchRenamer
	wave /T/SDFR=dfr wPaths, renamelistwave
	wave /SDFR=dfr sw
	ControlInfo /W=BatchRenamerPanel popupType
	string strType=RemoveEnding(s_value, "s")
	wave /T wNew=ListToTextWave(WS_SelectedObjectsList("BatchRenamerPanel", "listboxSelector"),";")
	int i
	int numItems=numpnts(wNew)
	for(i=0;i<numItems;i++)
		FindValue /TEXT=wNew[i]/TXOP=4 wPaths
		if(V_value>-1)
			continue
		endif
		wPaths[numpnts(wPaths)]={wNew[i]}
//		other possibilities for fake delete button: ❌❎⊗⨷⦻✘
		if(GrepString(strType, "Wave")) // unquote liberal wavenames
			renamelistwave[DimSize(renamelistwave,0)][]={{NameOfWave($wNew[i])},{strType},{""},{"\JC🅧"}}
		else
			renamelistwave[DimSize(renamelistwave,0)][]={{ParseFilePath(0, wNew[i], ":", 1, 0)},{strType},{""},{"\JC🅧"}}
		endif
	endfor
	redimension /N=(dimsize(wPaths, 0), -1, -1) sw
	setNewNames()
end

static function setNewNames()
	DFREF dfr = root:Packages:BatchRenamer
	wave /T/SDFR=dfr renamelistwave
	
	if(DimSize(renamelistwave,0)==0)
		generateCmd()
		return 0
	endif
	
	string strPre="", strSuf="", strThis="", strWith=""
	
	ControlInfo /W=BatchRenamerPanel checkPre
	if(V_Value)
		ControlInfo /W=BatchRenamerPanel setvarPrefix
		strPre=s_value
	endif
	ControlInfo /W=BatchRenamerPanel checkSuf
	if(V_Value)
		ControlInfo /W=BatchRenamerPanel setvarSuffix
		strSuf=s_value
	endif
	ControlInfo /W=BatchRenamerPanel setvarThis
	strThis=s_value
	ControlInfo /W=BatchRenamerPanel setvarWith
	strWith=s_value
	
	renamelistwave[][2]=strPre+ReplaceString(strThis,renamelistwave[p][0],strWith)+strSuf
	generateCmd()
end

static function generateCmd()
	DFREF dfr = root:Packages:BatchRenamer
	wave /T/SDFR=dfr wPaths, renamelistwave
	wave /SDFR=dfr sw
	
	int i
	int numItems=DimSize(wPaths,0)
	string cmd=""
	int error=0 // bitwise error code
	
	for(i=0;i<numItems;i++)
		string strFolder=ParseFilePath(1, wPaths[i], ":", 1, 0)
		DFREF folder=$strFolder
		if(DataFolderRefStatus(folder)!=1) // shouldn't arrive here
			//cmd = "** data folder does not exist **"
			error += 1-(error & 1)
			continue
		endif
		
		int type
		strswitch(renamelistwave[i][%Type])
			case "DataFolder":
				type=11
				break
			case "Wave":
				type=1
				break
			case "Variable":
				type=3
				break
			case "String":
				type=4
				break
		endswitch
		
		if(type==11) // data folder
			if(DataFolderExists(strFolder+":"+renamelistwave[i][%NewName]))
				//cmd = "** name conflict **"
				error += 2-(error & 2)
				sw[i][2][%foreColors]=1
				sw[i][2][%backColors]=3
				continue
			endif
			if(CheckName(renamelistwave[i][%NewName], 11))
				//cmd = "** illegal name **"
				error += 4-(error & 4)
				sw[i][2][%foreColors]=1
				sw[i][2][%backColors]=3
				continue
			endif
			sw[i][2][%foreColors]=0
			sw[i][2][%backColors]=0
			cmd += "RenameDataFolder " + wPaths[i] + " " + renamelistwave[i][%NewName] + "; "
		else
			if(exists(strFolder+PossiblyQuoteName(renamelistwave[i][%NewName])))
//				cmd = "** name conflict **"
				error += 2-(error & 2)
				sw[i][2][%foreColors]=1
				sw[i][2][%backColors]=3
				continue
			endif
			if(CheckName(renamelistwave[i][%NewName], type))
//				cmd = "** illegal name **"
				error += 4-(error & 4)
				sw[i][2][%foreColors]=1
				sw[i][2][%backColors]=3
				continue
			endif
			sw[i][2][%foreColors]=0
			sw[i][2][%backColors]=0
			if(DataFolderRefsEqual(GetDataFolderDFR(), folder))
				cmd += "Rename " + PossiblyQuoteName(renamelistwave[i][%Current]) + " " + PossiblyQuoteName(renamelistwave[i][%NewName]) + "; "
			else
				cmd += "Rename " + wPaths[i]  + " " +  PossiblyQuoteName(renamelistwave[i][%NewName]) + "; "
			endif
		endif
	endfor
	cmd=RemoveEnding(cmd, "; ")
	if(error)
		cmd=""
		if(error&1)
			cmd += "** data folder does not exist **\r"
		endif
		if(error&2)
			cmd += "** name conflict **\r"
		endif
		if(error&4)
			cmd += "** illegal name **\r"
		endif
		cmd=removeending(cmd, "\r")
	endif
	
	Notebook BatchRenamerPanel#nbCmd selection={startOfFile,endofFile}
	Notebook BatchRenamerPanel#nbCmd text=cmd
	Notebook BatchRenamerPanel#nbCmd selection={endofFile,endofFile}
	
	int disableButtons=2*(GrepString(cmd, "^\*"))
	Button buttonCmd, win=BatchRenamerPanel, disable=disableButtons
	Button buttonDoIt, win=BatchRenamerPanel, disable=disableButtons
	Button buttonClip, win=BatchRenamerPanel, disable=disableButtons
end

// function used by WaveSelectorWidget
static function filterFunc(string aName, variable contents)
	DFREF dfr = root:Packages:BatchRenamer
	SVAR strFilter=dfr:strFilter
	string leafName = ParseFilePath(0, aName, ":", 1, 0)
	int vFilter = 0
	try
		vFilter=GrepString(leafName, "(?i)"+strFilter); AbortOnRTE
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
		SVAR strFilter=root:Packages:BatchRenamer:strFilter
		strFilter=""
	endif
end

// intercept and deal with keyboard events in notebook subwindow
static function FilterHook(STRUCT WMWinHookStruct &s)
	
	if(s.eventcode==2) // window is being killed
		KillDataFolder /Z root:Packages:BatchRenamer
		SaveWindowPosition(s.winName)
		return 1
	endif
	
	if(s.eventcode==6) // resize
		GetWindow $s.winName wsize
		Notebook BatchRenamerPanel#nbCmd margins={0,0,435+(V_right-V_left)-470}
	endif
		
	GetWindow /Z BatchRenamerPanel#nbFilter active
	if(V_Value==0)
		return 0
	endif
	
	if(s.eventcode==22) // don't allow scrolling
		return 1
	endif
	
	DFREF dfr = root:Packages:BatchRenamer
	SVAR strFilter=dfr:strFilter
	int vLength=strlen(strFilter)
	
	if(s.eventcode==3 && vLength==0) // mousedown
		return 1 // don't allow mousedown when we have 'filter' displayed in nb
	endif
		
	if(s.eventcode==10) // menu
		strswitch(s.menuItem)
			case "Paste":
				string strScrap=GetScrapText()
				strScrap=ReplaceString("\r", strScrap, "")
				strScrap=ReplaceString("\n", strScrap, "")
				strScrap=ReplaceString("\t", strScrap, "")
				
				GetSelection Notebook, BatchRenamerPanel#nbFilter, 1 // get current position in notebook
				if(vLength==0)
					Notebook BatchRenamerPanel#nbFilter selection={startOfFile,endofFile}, text=strScrap
				else
					Notebook BatchRenamerPanel#nbFilter selection={(0,V_startPos),(0,V_endPos)}, text=strScrap
				endif
				vLength+=strlen(strScrap)-abs(V_endPos-V_startPos)
				s.eventcode=11
				// pretend this was a keyboard event to allow execution to continue
				break
			case "Cut":
				GetSelection Notebook, BatchRenamerPanel#nbFilter, 3 // get current position in notebook
				PutScrapText s_selection
				Notebook BatchRenamerPanel#nbFilter selection={(0,V_startPos),(0,V_endPos)}, text=""
				vLength-=strlen(s_selection)
				s.eventcode=11
				break
			case "Clear":
				GetSelection Notebook, BatchRenamerPanel#nbFilter, 3 // get current position in notebook
				Notebook BatchRenamerPanel#nbFilter selection={(0,V_startPos),(0,V_endPos)}, text="" // clear text
				vLength-=strlen(s_selection)
				s.eventcode=11
				break
		endswitch
		Button buttonClear, win=BatchRenamerPanel, disable=3*(vLength==0)
		ClearText((vLength==0))
	endif
				
	if(s.eventcode!=11)
		return 0
	endif
	
	if(vLength==0) // Remove "Filter" text before starting to deal with keyboard activity
		Notebook BatchRenamerPanel#nbFilter selection={startOfFile,endofFile}, text=""
	endif
	
	// deal with some non-printing characters
	switch(s.keycode)
		case 9:	// tab: jump to end
		case 3:
		case 13: // enter or return: jump to end
			Notebook BatchRenamerPanel#nbFilter selection={endOfFile,endofFile}
			break
		case 28: // left arrow
		case 29: // right arrow
			ClearText((vLength==0)); return (vLength==0)
		case 8:
		case 127: // delete or forward delete
			GetSelection Notebook, BatchRenamerPanel#nbFilter, 1
			if(V_startPos==V_endPos)
				V_startPos -= (s.keycode==8)
				V_endPos += (s.keycode==127)
			endif
			V_startPos=min(vLength,V_startPos); V_endPos=min(vLength,V_endPos)
			V_startPos=max(0, V_startPos); V_endPos=max(0, V_endPos)
			Notebook BatchRenamerPanel#nbFilter selection={(0,V_startPos),(0,V_endPos)}, text=""
			vLength-=abs(V_endPos-V_startPos)
			break
	endswitch
		
	// find and save current position
	GetSelection Notebook, BatchRenamerPanel#nbFilter, 1
	int selEnd=V_endPos
		
	if(strlen(s.keyText)==1) // a one-byte printing character
		// insert character into current selection
		Notebook BatchRenamerPanel#nbFilter text=s.keyText, textRGB=(0,0,0)
		vLength+=1-abs(V_endPos-V_startPos)
		// find out where we want to leave cursor
		GetSelection Notebook, BatchRenamerPanel#nbFilter, 1
		selEnd=V_endPos
	endif
	
	// select and format text
	Notebook BatchRenamerPanel#nbFilter selection={startOfFile,endOfFile}, textRGB=(0,0,0)
	// put text into global filter string
	GetSelection Notebook, BatchRenamerPanel#nbFilter, 3
	strFilter=s_selection
	Notebook BatchRenamerPanel#nbFilter selection={(0,selEnd),(0,selEnd)}, findText={"",1}
	
	Button buttonClear, win=BatchRenamerPanel, disable=3*(vLength==0)
	ClearText((vLength==0))
	
	WS_UpdateWaveSelectorWidget("BatchRenamerPanel", "listboxSelector")
	
	return 1 // tell Igor we've handled all keyboard events
end

static function setDimLabels(strList, dim, w)
	string strList
	int dim
	wave w
	
	int numLabels=ItemsInList(strList)
	int i
		
	if(numLabels!=DimSize(w, dim))
		return 0
	endif
	for(i=0;i<numLabels;i+=1)
		SetDimLabel dim, i, $StringFromList(i, strList), w
	endfor
	return 1
end

static function /S unquote(string s)
	if(GrepString(s, "(^').*('$)"))
		return s[1, strlen(s)-2]
	endif
	return s
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
