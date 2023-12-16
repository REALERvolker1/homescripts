use crate::procs;
use ratatui::{prelude::*, widgets::*};
use std::{
    env, io,
    path::{Path, PathBuf},
    rc,
};

use crossterm::{self, event, terminal, ExecutableCommand};
use eyre::{self, Context};

pub fn tui() -> eyre::Result<()> {
    terminal::enable_raw_mode()?;
    io::stdout()
        .execute(terminal::EnterAlternateScreen)
        .wrap_err("Failed to enter alternate screen")?;
    let mut terminal = Terminal::new(CrosstermBackend::new(io::stdout()))
        .wrap_err("Failed to create terminal backend on stdout")?;
    terminal.clear()?;

    let mut should_quit = false;
    let mut processes = procs::refresh()?;

    while !should_quit {
        terminal
            .draw(|frame| ui(frame, &processes))
            .wrap_err("Failed to draw ui")?;
        should_quit = handle_events().wrap_err("Failed to handle events properly")?;
    }

    // cleanup
    terminal::disable_raw_mode()
        .wrap_err("Failed to disable raw input mode! Your terminal session may be borked!")?;
    io::stdout().execute(terminal::LeaveAlternateScreen)?;
    Ok(())
}

fn handle_events() -> io::Result<bool> {
    if event::poll(std::time::Duration::from_millis(50))? {
        if let event::Event::Key(key) = event::read()? {
            if key.kind == event::KeyEventKind::Press && key.code == event::KeyCode::Char('q') {
                return Ok(true);
            }
        }
    }
    Ok(false)
}

fn ui(frame: &mut Frame, processes: &Vec<Vec<String>>) {
    let main_layout = Layout::default()
        .direction(Direction::Vertical)
        .constraints(
            [
                Constraint::Length(3),
                Constraint::Min(0),
                Constraint::Length(3),
            ]
            .as_ref(),
        )
        .split(frame.size());
    frame.render_widget(
        Block::new().borders(Borders::TOP).title("Status Bar"),
        main_layout[2],
    );
    frame.render_widget(Paragraph::new("Hello World!"), main_layout[0]);

    let processlayout: Vec<Row> = processes
        .iter()
        .map(|i| Row::new(i.iter().map(|i| Cell::from(i.to_owned()))))
        .collect();

    let processtable = Table::new(processlayout)
        .block(Block::default().borders(Borders::ALL).title("Processes"))
        .column_spacing(1)
        .highlight_style(Style::default().add_modifier(Modifier::BOLD));

    frame.render_widget(processtable, main_layout[1]);

    // let inner_layout = Layout::default()
    //     .direction(Direction::Horizontal)
    //     .constraints([Constraint::Percentage(50), Constraint::Percentage(50)])
    //     .split(main_layout[1]);
    // frame.render_widget(
    //     Block::default().borders(Borders::ALL).title("Left"),
    //     inner_layout[0],
    // );
    // frame.render_widget(
    //     Block::default().borders(Borders::ALL).title("Right"),
    //     inner_layout[1],
    // );

    // frame.render_widget(
    //     Paragraph::new("Hello World!")
    //         .block(Block::default().title("Greeting").borders(Borders::ALL)),
    //     frame.size(),
    // );
}
