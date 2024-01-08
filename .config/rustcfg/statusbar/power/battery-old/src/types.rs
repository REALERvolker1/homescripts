//! The properties of a block
use crate::*;
use ahash::*;
use futures::StreamExt;
use static_init::dynamic;
use std::sync::{Arc, Mutex};
use strum::IntoEnumIterator;
use strum_macros::EnumIter;

#[dynamic]
/// The global mutable state of this project
pub static mut STATE: Arc<Mutex<StateMux>> = Arc::new(Mutex::new(StateMux::new()));

/// The type for an icon
pub type Icon = &'static str;

/// What kind of output is requested
#[derive(Debug, Clone, Copy)]
pub enum OutputType {
    Stdout,
    Waybar,
    // TODO: Add more output types
}

/// The trait defining a module
pub trait Module {
    // TODO: Separate get_state and print
    /// Get the module's inner state
    fn get_state_string(&self, output_type: OutputType) -> String;
    /// Immediately require a full state update
    async fn refresh_state(&mut self) -> zbus::Result<()>;
    // /// Get the module's listeners
    // fn get_listeners<T>(&mut self) -> Vec<&mut Property<T>>;
}

/// The prototype for global mutable state of this project
#[derive(Debug, Default)]
pub struct StateMux {
    pub battery_state: battery::BatteryState,
    pub battery_rate: f64,
    pub battery_percentage: u8,
}
impl StateMux {
    pub fn new() -> StateMux {
        // let state_hash = PropertyListener::iter()
        //     .map(|x| (x.to_string(), x))
        //     .collect::<AHashMap<_, _>>();
        StateMux::default()
    }
}

/// A catch-all enum for all the possible Property listener types.
///
/// This is used for finding the struct to update
#[derive(Debug, Clone, Copy, Default, EnumIter, strum_macros::Display)]
pub enum PropertyListener {
    BatteryState(u32),
    BatteryPercentage(f64),
    BatteryRate(f64),
    PowerProfile,
    SuperGFX,
    #[default]
    None,
}

// Good riddance!
// /// A property that is being detected
// pub struct Property<'a, T> {
//     pub listener: PropertyListener,
//     pub value: T,
//     stream: zbus::PropertyStream<'a, T>,
// }
// impl<'a, T> Property<'a, T> {
//     /// Initialize a new property watcher. Remember to call `.parent_struct()` before use.
//     pub fn new(
//         listener_type: PropertyListener,
//         init_value: T,
//         stream: zbus::PropertyStream<'a, T>,
//     ) -> zbus::Result<Property<'a, T>> {
//         Ok(Self {
//             listener: listener_type,
//             value: init_value,
//             stream: stream,
//         })
//     }
//     /// aight look, the zbus ppl wrote it like this, don't give me a hard time about it
//     ///
//     /// Update the inner value if it is not an error, otherwise do nothing
//     pub async fn update(&mut self) -> ()
//     where
//         T: Unpin,
//         T: std::convert::From<zbus::zvariant::Value<'a>>,
//     {
//         if let Some(p) = self.stream.next().await {
//             if let Ok(v) = p.get_raw().await {
//                 if let Some(d) = v.clone().downcast() {
//                     self.value = d;
//                 }
//             }
//         }
//     }
// }
// // basically copied from zbus, required for self.stream.next()
// impl<'a, T> futures::Stream for Property<'a, T>
// where
//     T: Unpin,
// {
//     type Item = zbus::PropertyChanged<'a, T>;
//     fn poll_next(
//         self: std::pin::Pin<&mut Self>,
//         cx: &mut std::task::Context<'_>,
//     ) -> std::task::Poll<Option<Self::Item>> {
//         let m = self.get_mut();
//         m.stream.poll_next_unpin(cx)
//     }
//     fn size_hint(&self) -> (usize, Option<usize>) {
//         self.stream.size_hint()
//     }
// }
