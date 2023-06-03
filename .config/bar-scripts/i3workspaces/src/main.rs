use std::io::{self, Write};
use swayipc;

fn main() -> swayipc::Fallible<()> {
    let conn: swayipc::Connection = swayipc::Connection::new()?;
    let mut workspace_conn = swayipc::Connection::new()?;

    let mut stdout = io::stdout().lock();
    print_workspaces(&mut stdout, &mut workspace_conn)?;

    for _event in conn.subscribe([swayipc::EventType::Workspace])? {
        print_workspaces(&mut stdout, &mut workspace_conn)?;
    }
    Ok(())
}

fn print_workspaces(stdout: &mut io::StdoutLock ,conn: &mut swayipc::Connection) -> swayipc::Fallible<()> {
    let workspaces = conn.get_workspaces()?;

    let workspaces_fmt = workspaces.iter().map(|ws| {
        let state;
        if ws.focused {
            state = "focused"
        }
        else if ws.urgent {
            state = "urgent"
        }
        else if ws.visible {
            state = "visible"
        }
        else {
            state = "exists"
        }
        format!("{{\"name\": \"{}\", \"state\": \"{}\"}}", ws.name, state)
    }).collect::<Vec<String>>();
    stdout.write_fmt(format_args!("[{}]\n", workspaces_fmt.join(",")))?;
    Ok(())
}
