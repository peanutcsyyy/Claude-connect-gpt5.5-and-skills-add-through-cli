Set shell = CreateObject("Shell.Application")
Set fso = CreateObject("Scripting.FileSystemObject")

sessionName = WScript.Arguments(0)
distro = "Ubuntu"

If WScript.Arguments.Count > 1 Then
  distro = WScript.Arguments(1)
End If

scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
attachCmd = fso.BuildPath(scriptDir, "claude_tmux_attach.cmd")

shell.ShellExecute "cmd.exe", "/k """ & attachCmd & """ """ & sessionName & """ """ & distro & """", "", "open", 1
