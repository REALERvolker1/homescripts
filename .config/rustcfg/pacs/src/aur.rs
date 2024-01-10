use log::{debug, info, trace, warn};
use raur::Raur;

pub async fn aur_search(package: &str, raur: &raur::Handle) -> eyre::Result<()> {
    info!("Searching for '{}' in AUR...", package);
    // let packages = raur.search(package).await?;
    let packages = raur.search_by(package, raur::SearchBy::Name).await?;

    let selected = crate::search::select_from_list(
        packages
            .iter()
            .map(|p| crate::search::SearchItem::from_package(p)),
    )?;

    let selected_packages = packages
        .iter()
        .filter(|i| selected.contains(&i.name))
        .collect::<Vec<_>>();

    info!("Found {} packages", selected_packages.len());

    if log::log_enabled!(log::Level::Debug) {
        for pkg in selected_packages {
            debug!("Selected package {:?}", &pkg);
        }
    }

    Ok(())
}
