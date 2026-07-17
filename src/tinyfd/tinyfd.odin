package tinyfd

foreign import "tinyfiledialogs64.lib"

import _c "core:c"

import "core:sys/windows"

wstring :: windows.wstring

TINYFILEDIALOGS_H :: 1;


@(default_calling_convention="c")
foreign tinyfiledialogs64 {

    @(link_name="tinyfd_winUtf8")
    tinyfd_winUtf8 : _c.int;

    @(link_name="tinyfd_version")
    tinyfd_version : _c.char;

    @(link_name="tinyfd_needs")
    tinyfd_needs : _c.char;

    @(link_name="tinyfd_verbose")
    tinyfd_verbose : _c.int;

    @(link_name="tinyfd_silent")
    tinyfd_silent : _c.int;

    @(link_name="tinyfd_allowCursesDialogs")
    tinyfd_allowCursesDialogs : _c.int;

    @(link_name="tinyfd_forceConsole")
    tinyfd_forceConsole : _c.int;

    @(link_name="tinyfd_assumeGraphicDisplay")
    tinyfd_assumeGraphicDisplay : _c.int;

    @(link_name="tinyfd_response")
    tinyfd_response : _c.char;

    @(link_name="tinyfd_utf8toMbcs")
    utf8toMbcs :: proc(aUtf8string : cstring) -> cstring ---;

    @(link_name="tinyfd_utf16toMbcs")
    utf16toMbcs :: proc(aUtf16string : wstring) -> cstring ---;

    @(link_name="tinyfd_mbcsTo16")
    mbcsTo16 :: proc(aMbcsString : cstring) -> wstring ---;

    @(link_name="tinyfd_mbcsTo8")
    mbcsTo8 :: proc(aMbcsString : cstring) -> cstring ---;

    @(link_name="tinyfd_utf8to16")
    utf8to16 :: proc(aUtf8string : cstring) -> wstring ---;

    @(link_name="tinyfd_utf16to8")
    utf16to8 :: proc(aUtf16string : wstring) -> cstring ---;

    @(link_name="tinyfd_getGlobalChar")
    getGlobalChar :: proc(aCharVariableName : cstring) -> cstring ---;

    @(link_name="tinyfd_getGlobalInt")
    getGlobalInt :: proc(aIntVariableName : cstring) -> _c.int ---;

    @(link_name="tinyfd_setGlobalInt")
    setGlobalInt :: proc(aIntVariableName : cstring, aValue : _c.int) -> _c.int ---;

    @(link_name="tinyfd_beep")
    beep :: proc() ---;

    @(link_name="tinyfd_notifyPopup")
    notifyPopup :: proc(aTitle : cstring, aMessage : cstring, aIconType : cstring) -> _c.int ---;

    @(link_name="tinyfd_messageBox")
    messageBox :: proc(aTitle : cstring, aMessage : cstring, aDialogType : cstring, aIconType : cstring, aDefaultButton : _c.int) -> _c.int ---;

    @(link_name="tinyfd_inputBox")
    inputBox :: proc(aTitle : cstring, aMessage : cstring, aDefaultInput : cstring) -> cstring ---;

    @(link_name="tinyfd_saveFileDialog")
    saveFileDialog :: proc(aTitle : cstring, aDefaultPathAndOrFile : cstring, aNumOfFilterPatterns : _c.int, aFilterPatterns : ^cstring, aSingleFilterDescription : cstring) -> cstring ---;

    @(link_name="tinyfd_openFileDialog")
    openFileDialog :: proc(aTitle : cstring, aDefaultPathAndOrFile : cstring, aNumOfFilterPatterns : _c.int, aFilterPatterns : ^cstring, aSingleFilterDescription : cstring, aAllowMultipleSelects : _c.int) -> cstring ---;

    @(link_name="tinyfd_selectFolderDialog")
    selectFolderDialog :: proc(aTitle : cstring, aDefaultPath : cstring) -> cstring ---;

    @(link_name="tinyfd_colorChooser")
    colorChooser :: proc(aTitle : cstring, aDefaultHexRGB : cstring, aDefaultRGB : [3]_c.uchar, aoResultRGB : [3]_c.uchar) -> cstring ---;

    @(link_name="tinyfd_notifyPopupW")
    notifyPopupW :: proc(aTitle : wstring, aMessage : wstring, aIconType : wstring) -> _c.int ---;

    @(link_name="tinyfd_messageBoxW")
    messageBoxW :: proc(aTitle : wstring, aMessage : wstring, aDialogType : wstring, aIconType : wstring, aDefaultButton : _c.int) -> _c.int ---;

    @(link_name="tinyfd_inputBoxW")
    inputBoxW :: proc(aTitle : wstring, aMessage : wstring, aDefaultInput : wstring) -> wstring ---;

    @(link_name="tinyfd_saveFileDialogW")
    saveFileDialogW :: proc(aTitle : wstring, aDefaultPathAndOrFile : wstring, aNumOfFilterPatterns : _c.int, aFilterPatterns : ^wstring, aSingleFilterDescription : wstring) -> wstring ---;

    @(link_name="tinyfd_openFileDialogW")
    openFileDialogW :: proc(aTitle : wstring, aDefaultPathAndOrFile : wstring, aNumOfFilterPatterns : _c.int, aFilterPatterns : ^wstring, aSingleFilterDescription : wstring, aAllowMultipleSelects : _c.int) -> wstring ---;

    @(link_name="tinyfd_selectFolderDialogW")
    selectFolderDialogW :: proc(aTitle : wstring, aDefaultPath : wstring) -> wstring ---;

    @(link_name="tinyfd_colorChooserW")
    colorChooserW :: proc(aTitle : wstring, aDefaultHexRGB : wstring, aDefaultRGB : [3]_c.uchar, aoResultRGB : [3]_c.uchar) -> wstring ---;

}
