class SResetAllConfig extends GUICustomPropertyPage;

// May want to edit this so that it can only be operated clientside, so that
//		no outside unknowns can reset an innnocent player's scores.  That's evil 
//		shit man.

var automated GUIImage              i_Background;
var automated GUIMultiOptionListBox lb_SHS;
var GUIMultiOptionList              li_SHS;
var automated GUIButton				SConfigBackGround;
var automated GUIButton				SConfigYesButton;
var automated GUIButton				SConfigNoButton;

var	localized string SHSConfigTitle;
var SHighScore SHS;

var() class<SHighScore> HighScoreClass;

struct HighScoreType
{
	var string MapName;
	var int Score, Mask, ID;
	var bool erase;
	var moCheckBox CheckButton;
};

var array<HighScoreType> HighScores;
var array<int> toErase;

var bool bDebug;

function string GetResult()
{
	return "";
}


function InitScores()
{
	local int i,m,n;
	local byte c;
	local array<string> AS;
	local string S;
	
	if(bDebug)
		log("SResetAllConfig.InitScores(): HighScores.length = " $ HighScores.length, 'Swarms');
		
	SHS = New class 'SHighScore';
	
	HighScores.length = SHS.getArrayLength();

	m = 1;
	For( i=0; i<HighScores.length; i++ )
	{
		HighScores[i].Mask = m;
		m++;
		c = 0;
		S = Mid(AS[i],1,1);
		n = int(Left(AS[i],1));
		AS[i] = Mid(AS[i],2);
		HighScores[i].MapName = SHS.getMapFromArray(i);
		HighScores[i].Score = SHS.getScoreFromArray(i);
		if( Len(HighScores[i].MapName)>75 )
		{
			HighScores[i].MapName$="...";
			Break;
		}
	}
}

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
	local int i;

	Super.InitComponent(MyController, MyOwner);
	
		
	if(bDebug)
		log("SResetAllConfig.InitComponent(GUIController, GUIComponent)", 'Swarms');

	li_SHS = lb_SHS.List;
	li_SHS.OnChange = InternalOnChange;
	li_SHS.bDrawSelectionBorder = False;
	li_SHS.ItemPadding=0.15;
	li_SHS.ColumnWidth=0.95;
	li_SHS.bHotTrackSound = False;

	for ( i = 0; i < li_SHS.NumColumns; i++ )
		li_SHS.AddItem( "XInterface.GUIListSpacer" );

	sb_Main.ManageComponent(lb_SHS);
	sb_Main.LeftPadding=0;
	sb_Main.RightPadding=0;
	sb_Main.TopPadding=0.05;
	sb_Main.BottomPadding=0.05;
	sb_Main.SetPosition(0.030234,0.075000,0.851640,0.565624);
}

function SetOwner( GUIComponent NewOwner )
{
	Super.SetOwner(NewOwner);
	
	if(bDebug)
		log("SResetAllConfig.SetOwner(GUIComponent)", 'Swarms');

	t_WindowTitle.Caption = SHSConfigTitle;
	InitScores();
	InitializeList();
}

function InitializeList()
{
	local int i;
	local moCheckBox checkBox;
	
	SConfigBackGround.DisableMe();
	SConfigYesButton.DisableMe();
	SConfigNoButton.DisableMe();

	for ( i = 0; i<HighScores.Length; i++ )
	{
		checkBox = moCheckbox(li_SHS.AddItem( "XInterface.moCheckbox",, HighScores[i].MapName ));
		if ( checkBox != None )
		{
			HighScores[i].CheckButton = checkBox;
			HighScores[i].ID = i;
			HighScores[i].erase = false;
			checkBox.Tag = HighScores[i].Mask;
			checkBox.bAutoSizeCaption = True;
		}
		else
			log("SResetAllConfig.InitializeList(): Warning:  Created an empty checkbox", 'Swarms');
	}
}

function string GetDataString()
{
	if(bDebug)
		log("SResetAllConfig.GetDataString()", 'Swarms');
	return "";
}

function InternalOnChange(GUIComponent Sender){	
	local GUIMenuOption mo;
	if(bDebug)
		log("SResetAllConfig.InternalOnChange(GUIComponent)", 'Swarms');
	if ( Sender == li_SHS )
	{
		mo = li_SHS.Get();

		if ( moCheckBox(mo) != None )
		{
			if ( moCheckbox(mo).IsChecked() )
				HighScores[mo.Tag].erase = true;
			else HighScores[mo.Tag].erase = false;
		}
	}
}
/*
function bool InternalOnClick(GUIComponent Sender){
	if (Sender==Controls[1])
	{
		Controller.CloseMenu(false);
		return true;
	}
	else
	   Controller.CloseMenu(false);
	   
	return false;
}
*/

event Closed( GUIComponent Sender, bool bCancelled )
{
	local int i;

	if( bCancelled ){
		SHS = none;
		Return;
	}
	for( i=0; i<HighScores.length; i++ )
		if(HighScores[i].erase)
			toErase[toErase.length] = HighScores[i].ID;
	if(toErase.length>=1){
		for( i=0; i<toErase.length; i++ )
			SHS.resetScore(toErase[i]);
	}	
	SHS = none;
}

defaultproperties
{

    Begin Object Class=GUIMultiOptionListBox Name=SHSList
        bVisibleWhenEmpty=True
        OnCreateComponent=SHSList.InternalOnCreateComponent
        WinTop=0.150608
        WinLeft=0.007500
        WinWidth=0.983750
        WinHeight=0.698149
        TabOrder=1
        bBoundToParent=True
        bScaleToParent=True
        OnChange=KFInvWaveConfig.InternalOnChange
    End Object
    lb_SHS=GUIMultiOptionListBox'Swarms.SResetAllConfig.SHSList'
	 
	Begin Object Class=GUIButton Name=ConfirmBackground
        StyleName="SquareBar"
        WinHeight=1.000000
        bBoundToParent=false
        bScaleToParent=false
        bAcceptsInput=false
        bNeverFocus=false
        OnKeyEvent=ConfirmBackground.InternalOnKeyEvent
    End Object
	SConfigBackGround = GUIButton'Swarms.SResetAllConfig.ConfirmBackground'

    Begin Object Class=GUIButton Name=YesButton
        Caption="YES"
        WinTop=0.750000
        WinLeft=0.125000
        WinWidth=0.200000
        bBoundToParent=True
        OnClick=SResetAllConfig.InternalOnClick
        OnKeyEvent=YesButton.InternalOnKeyEvent
    End Object
    SConfigYesButton=GUIButton'Swarms.SResetAllConfig.YesButton'

    Begin Object Class=GUIButton Name=NoButton
        Caption="NO"
        WinTop=0.750000
        WinLeft=0.650000
        WinWidth=0.200000
        bBoundToParent=True
        OnClick=SResetAllConfig.InternalOnClick
        OnKeyEvent=NoButton.InternalOnKeyEvent
    End Object
    SConfigNoButton=GUIButton'Swarms.SResetAllConfig.NoButton'


    SHSConfigTitle="Swarms High Score Config Page"
    DefaultLeft=0.050000
    DefaultWidth=0.900000
    bDrawFocusedLast=False
    WinLeft=0.050000
    WinWidth=0.900000
	 
	HighScoreClass = class'Swarms.SHighScore'
	 
	bDebug = true
}