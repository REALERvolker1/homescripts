---@meta

---@alias VlkDirection
---| "left"
---| "right"
---| "up"
---| "down"

---@alias VlkToggleAction
---| "toggle"
---| "set"
---| "unset"

---@class VlkFocusArgs
---@field direction? VlkDirection
---@field workspace? HL.WorkspaceSelector
---@field monitor? HL.MonitorSelector
---@field window? HL.WindowSelector

---@class VlkWindowTargetArgs
---@field window? HL.WindowSelector

---@class VlkWindowMoveArgs
---@field direction? VlkDirection
---@field x? number
---@field y? number
---@field relative? boolean
---@field workspace? HL.WorkspaceSelector
---@field monitor? HL.MonitorSelector
---@field follow? boolean
---@field into_group? VlkDirection
---@field into_or_create_group? VlkDirection
---@field out_of_group? boolean|VlkDirection
---@field window? HL.WindowSelector

---@class VlkMouseResizeArgs
---@field keep_aspect_ratio? boolean

---@class VlkWindowResizeArgs
---@field x number
---@field y number
---@field relative? boolean
---@field window? HL.WindowSelector

---@class VlkWindowPseudoArgs
---@field action? VlkToggleAction
---@field window? HL.WindowSelector

---@class VlkWindowFloatArgs
---@field action? VlkToggleAction
---@field window? HL.WindowSelector

---@class VlkWindowFullscreenArgs
---@field action? VlkToggleAction
---@field window? HL.WindowSelector

---@class VlkGroupActiveArgs
---@field index integer
---@field window? HL.WindowSelector

---@class VlkGroupMoveWindowArgs
---@field forward? boolean

---@class VlkDspNamespace
---@field exec_cmd fun(command: string, rules?: table<string, string|number|boolean>): HL.Dispatcher
---@field exec_raw fun(command: string): HL.Dispatcher
---@field focus fun(args: VlkFocusArgs): HL.Dispatcher
---@field exit fun(): HL.Dispatcher
---@field layout fun(message: string): HL.Dispatcher
---@field submap fun(name: string): HL.Dispatcher
---@field force_idle fun(timeout: number): HL.Dispatcher
---@field group VlkDspGroupNamespace
---@field window VlkDspWindowNamespace
---@field workspace VlkDspWorkspaceNamespace

---@class VlkDspWindowNamespace
---@field close fun(args?: VlkWindowTargetArgs): HL.Dispatcher
---@field kill fun(args?: VlkWindowTargetArgs): HL.Dispatcher
---@field move fun(args: VlkWindowMoveArgs): HL.Dispatcher
---@field resize fun(args?: VlkWindowResizeArgs|VlkMouseResizeArgs): HL.Dispatcher
---@field pseudo fun(args?: VlkWindowPseudoArgs): HL.Dispatcher
---@field float fun(args?: VlkWindowFloatArgs): HL.Dispatcher
---@field fullscreen fun(args?: VlkWindowFullscreenArgs): HL.Dispatcher
---@field pin fun(args?: VlkWindowTargetArgs): HL.Dispatcher
---@field center fun(args?: VlkWindowTargetArgs): HL.Dispatcher
---@field drag fun(args?: VlkWindowTargetArgs): HL.Dispatcher

---@class VlkDspGroupNamespace
---@field toggle fun(args?: VlkWindowTargetArgs): HL.Dispatcher
---@field next fun(args?: VlkWindowTargetArgs): HL.Dispatcher
---@field prev fun(args?: VlkWindowTargetArgs): HL.Dispatcher
---@field active fun(args: VlkGroupActiveArgs): HL.Dispatcher
---@field move_window fun(args?: VlkGroupMoveWindowArgs): HL.Dispatcher

---@class VlkDspWorkspaceNamespace
---@field toggle_special fun(name?: string): HL.Dispatcher
---@field rename fun(args: table): HL.Dispatcher
---@field move fun(args: table): HL.Dispatcher
---@field swap_monitors fun(args: table): HL.Dispatcher
---@field change_id fun(args: table): HL.Dispatcher
