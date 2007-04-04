/*
 * FCKeditor - The text editor for internet
 * Copyright (C) 2003 Frederico Caldeira Knabben
 *
 * Licensed under the terms of the GNU Lesser General Public License
 * (http://www.opensource.org/licenses/lgpl-license.php)
 *
 * For further information go to http://www.fredck.com/FCKeditor/ 
 * or contact fckeditor@fredck.com.
 *
 * cz.js: Czech support.
 *
 * Authors:
 *   Plachow (plachow@atlas.cz)
 */

// Toolbar Items and Context Menu

lang["Cut"]					= "Vyjmout" ;
lang["Copy"]				= "Kopírovat" ;
lang["Paste"]				= "Vložit" ;
lang["PasteText"]			= "Vložit bez formátování" ;
lang["PasteWord"]			= "Vložit z Wordu" ;
lang["Find"]				= "Najít" ;
lang["SelectAll"]			= "Vybrat vše" ;
lang["RemoveFormat"]		= "Odstranit formátování" ;
lang["InsertLink"]			= "Vložit/zmìnit odkaz" ;
lang["RemoveLink"]			= "Odstranit odkaz" ;
lang["InsertImage"]			= "Vložit/zmìnit obrázek" ;
lang["InsertTable"]			= "Vložit/zmìnit tabulku" ;
lang["InsertLine"]			= "Vložit horizontální linku" ;
lang["InsertSpecialChar"]	= "Vložit speciální znak" ;
lang["InsertSmiley"]		= "Vložit smajlík" ;
lang["About"]				= "O aplikaci FCKeditor" ;

lang["Bold"]				= "Tuènì" ;
lang["Italic"]				= "Kurzíva" ;
lang["Underline"]			= "Podtržení" ;
lang["StrikeThrough"]		= "Pøeškrtnutí" ;
lang["Subscript"]			= "Spodní index" ;
lang["Superscript"]			= "Horní index" ;
lang["LeftJustify"]			= "Zarovnat vlevo" ;
lang["CenterJustify"]		= "Zarovnat na støed" ;
lang["RightJustify"]		= "Zarovnat vpravo" ;
lang["BlockJustify"]		= "Zarovnat do bloku" ;
lang["DecreaseIndent"]		= "Zmenšit odsazení" ;
lang["IncreaseIndent"]		= "Zvìtšit odsazení" ;
lang["Undo"]				= "Zpìt" ;
lang["Redo"]				= "Znovu" ;
lang["NumberedList"]		= "Èíslovaný seznam" ;
lang["BulettedList"]		= "Seznam s odrážkami" ;

lang["ShowTableBorders"]	= "Zobrazit ohranièení tabulek" ;
lang["ShowDetails"]			= "Zobrazit podrobnosti" ;

lang["FontStyle"]			= "Styl" ;
lang["FontFormat"]			= "Formát" ;
lang["Font"]				= "Písmo" ;
lang["FontSize"]			= "Velikost" ;
lang["TextColor"]			= "Barva textu" ;
lang["BGColor"]				= "Barva pozadí" ;
lang["Source"]				= "Zdroj" ;

// Context Menu

lang["EditLink"]			= "Vlastnosti odkazu" ;
lang["InsertRow"]			= "Vložit øádek" ;
lang["DeleteRows"]			= "Smazat øádek" ;
lang["InsertColumn"]		= "Vložit sloupec" ;
lang["DeleteColumns"]		= "Smazat sloupec" ;
lang["InsertCell"]			= "Vložit buòku" ;
lang["DeleteCells"]			= "Smazat buòky" ;
lang["MergeCells"]			= "Slouèit buòky" ;
lang["SplitCell"]			= "Rozdìlit buòku" ;
lang["CellProperties"]		= "Vlastnosti buòky" ;
lang["TableProperties"]		= "Vlastnosti tabulky" ;
lang["ImageProperties"]		= "Vlastnosti obrázku" ;

// Alerts and Messages

lang["ProcessingXHTML"]		= "Zpracovávám XHTML. Moment prosím..." ;
lang["Done"]				= "Hotovo" ;
lang["PasteWordConfirm"]	= "Text, který právì vkládáte do dokumentu, pochází pravdìpodobnì z Wordu.\nChcete provést vyèištìní zdojového kódu?" ;
lang["NotCompatiblePaste"]	= "Tento pøíkaz je funkèní pouze v IE verze 5.5 a vyšší. Chcete vložit text bez vyèištìní?" ;

// Dialogs
lang["DlgBtnOK"]			= "OK" ;
lang["DlgBtnCancel"]		= "Zrušit" ;
lang["DlgBtnClose"]			= "Zavøít" ;

// Image Dialog
lang["DlgImgTitleInsert"]	= "Vložit obrázek" ;
lang["DlgImgTitleEdit"]		= "Zmìnit obrázek" ;
lang["DlgImgBtnUpload"]		= "Poslat na server" ;
lang["DlgImgURL"]			= "URL" ;
lang["DlgImgUpload"]		= "Upload" ;
lang["DlgImgBtnBrowse"]		= "Procházet server" ;
lang["DlgImgAlt"]			= "Alternativní text" ;
lang["DlgImgWidth"]			= "Šíøka" ;
lang["DlgImgHeight"]		= "Výška" ;
lang["DlgImgLockRatio"]		= "Zachovat pomìr stran" ;
lang["DlgBtnResetSize"]		= "Pùvodní velikost" ;
lang["DlgImgBorder"]		= "Okraj" ;
lang["DlgImgHSpace"]		= "HSpace" ;
lang["DlgImgVSpace"]		= "VSpace" ;
lang["DlgImgAlign"]			= "Zarovnání" ;
lang["DlgImgAlignLeft"]		= "Left" ;
lang["DlgImgAlignAbsBottom"]	= "Abs Bottom" ;
lang["DlgImgAlignAbsMiddle"]	= "Abs Middle" ;
lang["DlgImgAlignBaseline"]	= "Baseline" ;
lang["DlgImgAlignBottom"]	= "Bottom" ;
lang["DlgImgAlignMiddle"]	= "Middle" ;
lang["DlgImgAlignRight"]	= "Right" ;
lang["DlgImgAlignTextTop"]	= "Text Top" ;
lang["DlgImgAlignTop"]		= "Top" ;
lang["DlgImgPreview"]		= "Náhled" ;
lang["DlgImgMsgWrongExt"]	= "Jsou povoleny pouze následující datové typy:\n\n" + config.ImageUploadAllowedExtensions + "\n\nOperace zrušena." ;
lang["DlgImgAlertSelect"]	= "Please select an image to upload." ;		// TODO

// Link Dialog
lang["DlgLnkWindowTitle"]	= "Link" ;		// TODO
lang["DlgLnkURL"]			= "URL" ;
lang["DlgLnkUpload"]		= "Upload" ;
lang["DlgLnkTarget"]		= "Cíl" ;
lang["DlgLnkTargetNotSet"]	= "<nenastaveno>" ;
lang["DlgLnkTargetBlank"]	= "Nové okno (_blank)" ;
lang["DlgLnkTargetParent"]	= "Rodièovské okno (_parent)" ;
lang["DlgLnkTargetSelf"]	= "Stejné okno (_self)" ;
lang["DlgLnkTargetTop"]		= "Hlavní okno (_top)" ;
lang["DlgLnkTitle"]			= "Nadpis" ;
lang["DlgLnkBtnUpload"]		= "Poslat na server" ;
lang["DlgLnkBtnBrowse"]		= "Procházet server" ;
lang["DlgLnkMsgWrongExtA"]	= "Pro upload jsou povoleny pouze následující datové typy:\n\n" + config.LinkUploadAllowedExtensions + "\n\nOperace zrušena." ;
lang["DlgLnkMsgWrongExtD"]	= "Tyto datové typy nejsou povoleny pro upload:\n\n" + config.LinkUploadDeniedExtensions + "\n\nOperace zrušena." ;

// Color Dialog
lang["DlgColorTitle"]		= "Vyberte barvu" ;
lang["DlgColorBtnClear"]	= "Vymazat" ;
lang["DlgColorHighlight"]	= "Zvýraznit" ;
lang["DlgColorSelected"]	= "Vybraná" ;

// Smiley Dialog
lang["DlgSmileyTitle"]		= "Vložení smajlíku" ;

// Special Character Dialog
lang["DlgSpecialCharTitle"]	= "Vložení speciálního znaku" ;

// Table Dialog
lang["DlgTableTitleInsert"]	= "Vložení tabulky" ;
lang["DlgTableTitleEdit"]	= "Editace tabulky" ;
lang["DlgTableRows"]		= "Øádky" ;
lang["DlgTableColumns"]		= "Sloupce" ;
lang["DlgTableBorder"]		= "Tlouška okrajù" ;
lang["DlgTableAlign"]		= "Zarovnání" ;
lang["DlgTableAlignNotSet"]	= "<nenastaveno>" ;
lang["DlgTableAlignLeft"]	= "Vlevo" ;
lang["DlgTableAlignCenter"]	= "Na støed" ;
lang["DlgTableAlignRight"]	= "Vpravo" ;
lang["DlgTableWidth"]		= "Šíøka" ;
lang["DlgTableWidthPx"]		= "pixelù" ;
lang["DlgTableWidthPc"]		= "procent" ;
lang["DlgTableHeight"]		= "Výška" ;
lang["DlgTableCellSpace"]	= "Mezera mezi buòkami" ;
lang["DlgTableCellPad"]		= "Odsazení v buòce" ;
lang["DlgTableCaption"]		= "Titulek" ;

// Table Cell Dialog
lang["DlgCellTitle"]		= "Vlastnosti buòky" ;
lang["DlgCellWidth"]		= "Šíøka" ;
lang["DlgCellWidthPx"]		= "pixelù" ;
lang["DlgCellWidthPc"]		= "procent" ;
lang["DlgCellHeight"]		= "Výška" ;
lang["DlgCellWordWrap"]		= "Zalomení textu" ;
lang["DlgCellWordWrapNotSet"]	= "<nenastaveno>" ;
lang["DlgCellWordWrapYes"]		= "Ano" ;
lang["DlgCellWordWrapNo"]		= "ne" ;
lang["DlgCellHorAlign"]		= "Horizontální zarovnání" ;
lang["DlgCellHorAlignNotSet"]	= "<nenastaveno>" ;
lang["DlgCellHorAlignLeft"]		= "Vlevo" ;
lang["DlgCellHorAlignCenter"]	= "Na støed" ;
lang["DlgCellHorAlignRight"]	= "Vpravo" ;
lang["DlgCellVerAlign"]		= "Vertikální zarovnání" ;
lang["DlgCellVerAlignNotSet"]	= "<nenastaveno>" ;
lang["DlgCellVerAlignTop"]		= "Top" ;
lang["DlgCellVerAlignMiddle"]	= "Middle" ;
lang["DlgCellVerAlignBottom"]	= "Bottom" ;
lang["DlgCellVerAlignBaseline"]	= "Baseline" ;
lang["DlgCellRowSpan"]		= "Spøežení øádkù" ;
lang["DlgCellCollSpan"]		= "Spøežení sloupcù" ;
lang["DlgCellBackColor"]	= "Barva pozadí" ;
lang["DlgCellBorderColor"]	= "Barva okrajù" ;
lang["DlgCellBtnSelect"]	= "Vybrat..." ;

// About Dialog
lang["DlgAboutVersion"]		= "verze" ;
lang["DlgAboutLicense"]		= "Licensed under the terms of the GNU Lesser General Public License" ;
lang["DlgAboutInfo"]		= "For further information go to" ;