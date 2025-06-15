/**
 * @type {number}
 */
let n_pings = 0
/**
 * @type {number | null}
 */
let ping_interval = null

document.addEventListener("DOMContentLoaded", () => {
    ping_interval = setInterval(() => {
        let elem = document.createElement("button")
        elem.innerText = `Ping ${n_pings} (click to stop)`
        elem.addEventListener("click", () => {
            if (ping_interval === null) return

            clearInterval(ping_interval)
            ping_interval = null
        })
        n_pings += 1

        document.querySelector("body").appendChild(elem)
    }, 2000)
})
