use crate::RelayMessage;

// use lockfree::queue::Queue;
use ockam_core::Message;
use tokio::{runtime::Runtime, sync::mpsc::Receiver};

pub struct Mailbox<M>
where
    M: Message + Send,
{
    buf: VecDeque<M>,
}

pub enum MsgHandle {
    Empty,
    Ok,
    Return,
}

impl<M> Mailbox<M>
where
    M: Message + Send,
{
    pub fn new() -> Self {
        Self { buf: Queue::new() }
    }

    /// Call a closure with a message, optionally re-inserting it
    ///
    /// This function solves the issue around message state.  If a
    /// worker is waiting for a particular type of message by calling
    /// `.receive().await` on it's context handle, the provided
    /// closure can fail to let the mailbox know to re-queue the
    /// message.  In this case the receive will try to resolve the
    /// next message in the mailbox.
    ///
    /// **Warning:** this mechanism may cause an infinite loop
    pub fn try_next<F>(&mut self, cb: F) -> MsgHandle
    where
        F: Fn(&M) -> MsgHandle,
    {
        let msg = match self.buf.pop_front() {
            Some(msg) => msg,
            None => return MsgHandle::Empty,
        };

        let ret = cb(&msg);

        if ret == MsgHandle::Return {
            self.buf.push_back(msg);
        }

        ret
    }
}
