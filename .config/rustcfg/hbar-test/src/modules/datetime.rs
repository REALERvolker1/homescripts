use crate::*;

const TIME_FORMAT: &str = "%H:%M:%S";
const TIME_POLL_DELAY: Duration = Duration::from_secs(1);

pub struct DateTime {
    inner: Arc<String>,
}
impl Module for DateTime {
    async fn run(&mut self, runtime_data: RuntimeData, mpsc_sender: Sender<MpscData>) -> NoBruh {
        loop {
            // TODO: Find if there is a better way to do this
            let time = chrono::Local::now();
            self.inner = Arc::new(time.format(TIME_FORMAT).to_string());

            mpsc_sender
                .send(MpscData::DateTime(Arc::clone(&self.inner)))
                .await?;

            sleep(TIME_POLL_DELAY).await;
        }
    }
}
