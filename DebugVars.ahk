﻿
#Include TreeListView.ahk

/*
    DebugVars
    
    Public interface:
        dv := new DebugVars(RootNode)
        dv.TLV
        dv.Show()
        dv.Hide()
        dv.OnContextMenu := Func(dv, node, isRightClick, x, y)
*/
class DebugVars extends TreeListView._Base
{
    static Instances := {} ; Hwnd:Object map of *visible* instances
    
    __New(RootNode) {
        restore_gui_on_return := new TreeListView.GuiScope()
        Gui New, hwndhGui LabelDebugVars_Gui +Resize
        this.hGui := hGui
        Gui Margin, 0, 0
        this.TLV := new this.Control(RootNode
            , "w500 h300 -LV0x10 -Multi", "Name|Value") ; LV0x10 = LVS_EX_HEADERDRAGDROP
        Gui -DPIScale
    }
    
    class Control extends TreeListView
    {
        static COL_NAME := 1, COL_VALUE := 2
        
        MinEditColumn := 2
        MaxEditColumn := 2
        
        AutoSizeValueColumn() {
            LV_ModifyCol(this.COL_VALUE, "AutoHdr")
        }
        
        AfterPopulate() {
            LV_ModifyCol(this.COL_NAME, 150)
            this.AutoSizeValueColumn()
        }
        
        ExpandContract(r) {
            base.ExpandContract(r)
            this.AutoSizeValueColumn()  ; Adjust for +/-scrollbars
        }
        
        BeforeHeaderResize(column) {
            if (column != this.COL_NAME)
                return true
            ; Collapse to fit just the value so that scrollbars will be
            ; visible only when needed.
            LV_ModifyCol(this.COL_VALUE, "Auto")
        }
        
        AfterHeaderResize(column) {
            this.AutoSizeValueColumn()
        }
        
        SetNodeValue(node, column, value) {
            if (column != this.COL_VALUE)
                return
            if (node.SetValue(value) = 0)
                return
            if !(r := this.RowFromNode(node))
                return
            LV_Modify(r, "Col" column, value)
            if (!node.expandable && node.children) {
                ; Since value is a string, node can't be expanded
                LV_Modify(r, "Icon1 Col2")
                this.RemoveChildren(r+1, node)
                node.children := ""
                node.expanded := false
            }
        }
    }
    
    Show(options:="", title:="") {
        this.RegisterHwnd()
        Gui % this.hGui ":Show", % options, % title
    }
    
    Hide() {
        Gui % this.hGui ":Hide"
        DebugVars.UnregisterHwnd(this.hGui)
    }
    
    RegisterHwnd() {
        DebugVars.Instances[this.hGui] := this
    }
    
    UnregisterHwnd(hwnd) {
        DebugVars.Instances.Delete(hwnd)
    }
    
    __Delete() {
        Gui % this.hGui ":Destroy"
    }
    
    ContextMenu(ctrlHwnd, eventInfo, isRightClick, x, y) {
        if (ctrlHwnd != this.TLV.hLV || !this.OnContextMenu)
            return
        node := eventInfo ? this.TLV.NodeFromRow(eventInfo) : ""
        this.OnContextMenu(node, isRightClick, x, y)
    }
}

DebugVars_GuiClose(hwnd) {
    DebugVars.UnregisterHwnd(hwnd)
}

DebugVars_GuiEscape(hwnd) {
    DebugVars.Instances[hwnd].Hide()
}

DebugVars_GuiSize(hwnd, e, w, h) {
    GuiControl Move, SysListView321, w%w% h%h%
    DebugVars.Instances[hwnd].TLV.AutoSizeValueColumn()
}

DebugVars_GuiContextMenu(hwnd, prms*) {
    DebugVars.Instances[hwnd].ContextMenu(prms*)
}
