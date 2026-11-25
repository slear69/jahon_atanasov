import ctypes
import shutil
import subprocess
import tkinter as tk
from pathlib import Path
from tkinter import messagebox


WINDOW_TITLE = "Setup Launcher"
WINDOWS_NEW_CONSOLE = getattr(subprocess, "CREATE_NEW_CONSOLE", 0x00000010)
SW_SHOWNORMAL = 1


def get_powershell() -> str | None:
    return (
        shutil.which("powershell.exe")
        or shutil.which("powershell")
        or shutil.which("pwsh")
    )


def launch_script(script_name: str, *, elevated: bool = False) -> None:
    script_path = Path(__file__).resolve().with_name(script_name)
    if not script_path.is_file():
        messagebox.showerror(
            WINDOW_TITLE,
            f"Could not find {script_name} next to the launcher.",
        )
        return

    powershell = get_powershell()
    if powershell is None:
        messagebox.showerror(
            WINDOW_TITLE,
            "PowerShell was not found. Install Windows PowerShell or PowerShell 7.",
        )
        return

    arguments = ["-NoExit", "-NoProfile", "-File", str(script_path)]
    try:
        if elevated and not ctypes.windll.shell32.IsUserAnAdmin():
            shell_execute = ctypes.windll.shell32.ShellExecuteW
            shell_execute.restype = ctypes.c_void_p
            shell_execute.argtypes = [
                ctypes.c_void_p,
                ctypes.c_wchar_p,
                ctypes.c_wchar_p,
                ctypes.c_wchar_p,
                ctypes.c_wchar_p,
                ctypes.c_int,
            ]
            result = shell_execute(
                None,
                "runas",
                powershell,
                subprocess.list2cmdline(arguments),
                str(script_path.parent),
                SW_SHOWNORMAL,
            )
            if result <= 32:
                if result == 5:
                    messagebox.showinfo(WINDOW_TITLE, "Administrator approval was canceled.")
                else:
                    messagebox.showerror(
                        WINDOW_TITLE,
                        f"Could not start the elevated setup (Windows error {result}).",
                    )
        else:
            subprocess.Popen(
                [powershell, *arguments],
                cwd=script_path.parent,
                creationflags=WINDOWS_NEW_CONSOLE,
            )
    except OSError as error:
        messagebox.showerror(WINDOW_TITLE, f"Could not start PowerShell:\n{error}")


def main() -> None:
    root = tk.Tk()
    root.title(WINDOW_TITLE)
    root.resizable(False, False)
    root.configure(padx=22, pady=18)

    tk.Label(
        root,
        text="Choose a setup",
        font=("Segoe UI", 16, "bold"),
    ).pack(anchor="w")
    tk.Label(
        root,
        text=(
            "Each setup runs in its own PowerShell window. Review its prompts "
            "before accepting changes."
        ),
        justify="left",
        wraplength=380,
        font=("Segoe UI", 10),
    ).pack(anchor="w", pady=(6, 16))

    tk.Button(
        root,
        text="Programming setup",
        width=30,
        command=lambda: launch_script("programing.ps1"),
    ).pack(anchor="w", pady=4)
    tk.Label(
        root,
        text="Installs and configures developer tools and editor settings.",
        wraplength=380,
        justify="left",
        font=("Segoe UI", 9),
    ).pack(anchor="w", pady=(0, 10))

    tk.Button(
        root,
        text="Gaming setup (administrator)",
        width=30,
        command=lambda: (
            messagebox.askyesno(
                WINDOW_TITLE,
                "The gaming setup can change Windows settings and install apps.\n"
                "Continue and allow administrator access if requested?",
            )
            and launch_script("gaiming.ps1", elevated=True)
        ),
    ).pack(anchor="w", pady=4)
    tk.Label(
        root,
        text="May change Game Mode, power settings, or GPU scheduling.",
        wraplength=380,
        justify="left",
        font=("Segoe UI", 9),
    ).pack(anchor="w", pady=(0, 14))

    tk.Button(root, text="Close", width=12, command=root.destroy).pack(anchor="e")
    root.mainloop()


if __name__ == "__main__":
    main()
