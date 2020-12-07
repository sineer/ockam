#![no_std]
extern crate alloc;
use alloc::boxed::Box;
use alloc::collections::VecDeque;
use alloc::rc::Rc;
use alloc::string::String;
use core::cell::RefCell;
use core::ops::DerefMut;
use ockam_message::message::{AddressType, Message};

pub trait HandleMessage {
    fn handle_message(
        &mut self,
        message: Message, //todo - add context
        queue: Rc<RefCell<dyn RouteMessage<Message>>>,
    ) -> Result<bool, String>;
}

/// Poll trait is for workers to get cpu cycles on a regular basis.
///
/// A worker gets polled by registering its address and Poll trait with the Node.
/// poll() will be called once each polling interval.
pub trait Poll { //todo - add context
    fn poll(&mut self, q_ref: Rc<RefCell<dyn RouteMessage<Message>>>) -> Result<bool, String>;
}

/// Enqueue trait is used by Workers to enqueue messages for routing.
///
/// The Enqueue trait is passed to a Worker each time it is sent a message or polled.
pub trait RouteMessage<T> {
    fn route_message(&mut self, t: T) -> Result<bool, String>;
}

impl<T> RouteMessage<T> for VecDeque<T> {
    fn route_message(&mut self, t: T) -> Result<bool, String> {
        self.push_back(t);
        Ok(true)
    }
}