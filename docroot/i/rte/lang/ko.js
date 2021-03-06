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
 * ko.js: Korean support.
 *
 * Authors:
 *   Kwag, Taehwan (thkwag@nate.com)
 */

// Toolbar Items and Context Menu

lang["Cut"]					= "잘라내기" ;
lang["Copy"]				= "복사하기" ;
lang["Paste"]				= "붙여넣기" ;
lang["PasteText"]			= "텍스트로 붙여넣기" ;
lang["PasteWord"]			= "MS Word 형식으로 붙여넣기" ;
lang["Find"]				= "찾기" ;
lang["SelectAll"]			= "전체선택" ;
lang["RemoveFormat"]		= "포맷 지우기" ;
lang["InsertLink"]			= "하이퍼링크 삽입/변경" ;
lang["RemoveLink"]			= "하이퍼링크 삭제" ;
lang["InsertImage"]			= "이미지 삽입/변경" ;
lang["InsertTable"]			= "테이블 삽입/변경" ;
lang["InsertLine"]			= "수평선 삽입" ;
lang["InsertSpecialChar"]	= "특수문자 삽입" ;
lang["InsertSmiley"]		= "아이콘 삽입" ;
lang["About"]				= "FCKeditor에 대하여" ;

lang["Bold"]				= "진하게" ;
lang["Italic"]				= "이텔릭" ;
lang["Underline"]			= "밑줄" ;
lang["StrikeThrough"]		= "취소선" ;
lang["Subscript"]			= "아래 첨자" ;
lang["Superscript"]			= "위 첨자" ;
lang["LeftJustify"]			= "왼쪽 정렬" ;
lang["CenterJustify"]		= "가운데 정렬" ;
lang["RightJustify"]		= "오른쪽 정렬" ;
lang["BlockJustify"]		= "양쪽 맞춤" ;
lang["DecreaseIndent"]		= "내어쓰기" ;
lang["IncreaseIndent"]		= "들여쓰기" ;
lang["Undo"]				= "취소" ;
lang["Redo"]				= "재실행" ;
lang["NumberedList"]		= "순서있는 목록" ;
lang["BulettedList"]		= "순서없는 목록" ;

lang["ShowTableBorders"]	= "테이블 테두리 보기" ;
lang["ShowDetails"]			= "문서기호 보기" ;

lang["FontStyle"]			= "스타일" ;
lang["FontFormat"]			= "포맷" ;
lang["Font"]				= "폰트" ;
lang["FontSize"]			= "글자 크기" ;
lang["TextColor"]			= "글자 색상" ;
lang["BGColor"]				= "배경 색상" ;
lang["Source"]				= "<b>HTML 소스</b>" ;

// Context Menu

lang["EditLink"]			= "하아퍼링크 수정" ;
lang["InsertRow"]			= "가로줄 삽입" ;
lang["DeleteRows"]			= "가로줄 삭제" ;
lang["InsertColumn"]		= "세로줄 삽입" ;
lang["DeleteColumns"]		= "세로줄 삭제" ;
lang["InsertCell"]			= "셀 삽입" ;
lang["DeleteCells"]			= "셀 삭제" ;
lang["MergeCells"]			= "셀 합치기" ;
lang["SplitCell"]			= "셀 나누기" ;
lang["CellProperties"]		= "셀 속성" ;
lang["TableProperties"]		= "테이블 속성" ;
lang["ImageProperties"]		= "이미지 속성" ;

// Alerts and Messages

lang["ProcessingXHTML"]		= "XHTML 처리중. 잠시만 기다려주십시요." ;
lang["Done"]				= "완료" ;
lang["PasteWordConfirm"]	= "붙여넣기 할 텍스트는 MS Word에서 복사한 것입니다. 붙여넣기 전에 포멧을 삭제하시겠습니까?" ;
lang["NotCompatiblePaste"]	= "이 명령은 인터넷익스플로러 5.5 버전 이상에서만 작동합니다. 포멧을 삭제하지 않고 붙여넣기 하시겠습니까?" ;

// Dialogs
lang["DlgBtnOK"]			= "예" ;
lang["DlgBtnCancel"]		= "아니오" ;
lang["DlgBtnClose"]			= "닫기" ;

// Image Dialog
lang["DlgImgTitleInsert"]	= "이미지 삽입" ;
lang["DlgImgTitleEdit"]		= "이미지 수정" ;
lang["DlgImgBtnUpload"]		= "서버로 전송" ;
lang["DlgImgURL"]			= "URL" ;
lang["DlgImgUpload"]		= "업로드" ;
lang["DlgImgBtnBrowse"]		= "이미지 보기" ;
lang["DlgImgAlt"]			= "그림 설명" ;
lang["DlgImgWidth"]			= "너비" ;
lang["DlgImgHeight"]		= "높이" ;
lang["DlgImgLockRatio"]		= "비율 유지" ;
lang["DlgBtnResetSize"]		= "원래 크기로" ;
lang["DlgImgBorder"]		= "테두리" ;
lang["DlgImgHSpace"]		= "수평정렬" ;
lang["DlgImgVSpace"]		= "수직정렬" ;
lang["DlgImgAlign"]			= "정렬" ;
lang["DlgImgAlignLeft"]		= "왼쪽" ;
lang["DlgImgAlignAbsBottom"]	= "줄아래(Abs Bottom)" ;
lang["DlgImgAlignAbsMiddle"]	= "줄중간(Abs Middle)" ;
lang["DlgImgAlignBaseline"]	= "기준선" ;
lang["DlgImgAlignBottom"]	= "아래" ;
lang["DlgImgAlignMiddle"]	= "중간" ;
lang["DlgImgAlignRight"]	= "오른쪽" ;
lang["DlgImgAlignTextTop"]	= "글자위(Text Top)" ;
lang["DlgImgAlignTop"]		= "위" ;
lang["DlgImgPreview"]		= "미리보기" ;
lang["DlgImgMsgWrongExt"]	= "죄송합니다. 다음 확장자를 가진 파일만 업로드 할 수 있습니다. :\n\n" + config.ImageUploadAllowedExtensions + "\n\n작업이 취소되었습니다." ;
lang["DlgImgAlertSelect"]	= "업로드 할 이미지를 선택하십시요." ;		// NEW


// Link Dialog
lang["DlgLnkWindowTitle"]	= "링크" ;		// NEW
lang["DlgLnkURL"]			= "URL" ;
lang["DlgLnkUpload"]		= "업로드" ;
lang["DlgLnkTarget"]		= "대상" ;
lang["DlgLnkTargetNotSet"]	= "<기본값>" ;
lang["DlgLnkTargetBlank"]	= "New Window (_blank)" ;
lang["DlgLnkTargetParent"]	= "Parent Window (_parent)" ;
lang["DlgLnkTargetSelf"]	= "Same Window (_self)" ;
lang["DlgLnkTargetTop"]		= "Topmost Window (_top)" ;
lang["DlgLnkTitle"]			= "제목" ;
lang["DlgLnkBtnUpload"]		= "업로드" ;
lang["DlgLnkBtnBrowse"]		= "저장된 파일 보기" ;
lang["DlgLnkMsgWrongExtA"]	= "죄송합니다. 다음 확장자를 가진 파일만 업로드 할 수 있습니다. :\n\n" + config.LinkUploadAllowedExtensions + "\n\n작업이 취소되었습니다." ;
lang["DlgLnkMsgWrongExtD"]	= "죄송합니다. 다음 확장자를 가진 파일은 업로드 할 수 없습니다. :\n\n" + config.LinkUploadDeniedExtensions + "\n\n작업이 취소되었습니다." ;

// Color Dialog
lang["DlgColorTitle"]		= "색상 선택" ;
lang["DlgColorBtnClear"]	= "선택 취소" ;
lang["DlgColorHighlight"]	= "Highlight" ;
lang["DlgColorSelected"]	= "Selected" ;

// Smiley Dialog
lang["DlgSmileyTitle"]		= "아이콘 삽입" ;

// Special Character Dialog
lang["DlgSpecialCharTitle"]	= "특수문자 삽입" ;

// Table Dialog
lang["DlgTableTitleInsert"]	= "테이블 삽입" ;
lang["DlgTableTitleEdit"]	= "테이블 수정" ;
lang["DlgTableRows"]		= "가로줄" ;
lang["DlgTableColumns"]		= "세로줄" ;
lang["DlgTableBorder"]		= "테두리" ;
lang["DlgTableAlign"]		= "정렬" ;
lang["DlgTableAlignNotSet"]	= "<기본값>" ;
lang["DlgTableAlignLeft"]	= "왼쪽" ;
lang["DlgTableAlignCenter"]	= "가운데" ;
lang["DlgTableAlignRight"]	= "오른쪽" ;
lang["DlgTableWidth"]		= "너비" ;
lang["DlgTableWidthPx"]		= "픽셀" ;
lang["DlgTableWidthPc"]		= "%" ;
lang["DlgTableHeight"]		= "높이" ;
lang["DlgTableCellSpace"]	= "셀 간격" ;
lang["DlgTableCellPad"]		= "안쪽 여백" ;
lang["DlgTableCaption"]		= "캡션" ;

// Table Cell Dialog
lang["DlgCellTitle"]		= "셀 속성" ;
lang["DlgCellWidth"]		= "너비" ;
lang["DlgCellWidthPx"]		= "픽셀" ;
lang["DlgCellWidthPc"]		= "%" ;
lang["DlgCellHeight"]		= "너비" ;
lang["DlgCellWordWrap"]		= "워드랩" ;
lang["DlgCellWordWrapNotSet"]	= "<기본값>" ;
lang["DlgCellWordWrapYes"]		= "예" ;
lang["DlgCellWordWrapNo"]		= "아니오" ;
lang["DlgCellHorAlign"]			= "수평 정렬" ;
lang["DlgCellHorAlignNotSet"]	= "<기본값>" ;
lang["DlgCellHorAlignLeft"]		= "왼쪽" ;
lang["DlgCellHorAlignCenter"]	= "가운데" ;
lang["DlgCellHorAlignRight"]	= "오른쪽" ;
lang["DlgCellVerAlign"]			= "수직정렬" ;
lang["DlgCellVerAlignNotSet"]	= "<기본값>" ;
lang["DlgCellVerAlignTop"]		= "위" ;
lang["DlgCellVerAlignMiddle"]	= "중간" ;
lang["DlgCellVerAlignBottom"]	= "아래" ;
lang["DlgCellVerAlignBaseline"]	= "기준선" ;
lang["DlgCellRowSpan"]		= "Rows Span" ;
lang["DlgCellCollSpan"]		= "Columns Span" ;
lang["DlgCellBackColor"]	= "배경 색상" ;
lang["DlgCellBorderColor"]	= "테드리 색상" ;
lang["DlgCellBtnSelect"]	= "선택" ;

// About Dialog
lang["DlgAboutVersion"]		= "version" ;
lang["DlgAboutLicense"]		= "Licensed under the terms of the GNU Lesser General Public License" ;
lang["DlgAboutInfo"]		= "For further information go to" ;