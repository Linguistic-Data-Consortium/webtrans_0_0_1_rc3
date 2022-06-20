import "./collected_urls.css";
import App from "./collected_urls_form.svelte";
import { Guide } from "../guides/guide";

document.addEventListener('DOMContentLoaded', () => {
    const app = new App({
        target: document.querySelector("div#main")
    });
    notif.init();
});

const notif = new Guide("New 'Chapters' Feature");
const appear = s => notif.wait(s), disappear = s => appear(s, false);
const promise = f => notif.promise(f);

console.log("Hello from collected_urls.js; guide created",notif);

const new_interface = notif.step("New interface", async ()=>{
    const chapter = await appear(".chapter");
    await chapter.tte(
        "<p>This new interface allows you to report multiple <strong>Chapters</strong>.</p>\
         <p>Let's walk you through how to do that.</p>",
        "right", "middle", "cover", {click: true}
    ).promise;
    fill_chapter();
})
const fill_chapter = notif.step("Fill first chapter", async()=>{
    const chapter = await appear(".chapter");
    await chapter.tte(
        "<p>First fill this form with any value.</p>",
        "right", "middle", "cover", {
            click: false,
            promise:r=>{
                const filled = {select: false, date: false, time: false};
                const checkFilled = prop=>{
                    filled[prop] = true;
                    if (filled.select/*&&filled.date&&filled.time*/) {
                        r();
                        document.querySelector("#collected_url_starts_at_date").blur();
                        document.querySelector("#collected_url_starts_at_time").blur();
                    }
                };
                document.querySelector("#collected_url_center").addEventListener("change",()=>checkFilled('select'));
                // document.querySelector("#collected_url_starts_at_date").addEventListener("change",()=>checkFilled('date'));
                // document.querySelector("#collected_url_starts_at_time").addEventListener("change",()=>checkFilled('time'));
            }
        }
    ).promise;
    await new Promise(r=>setTimeout(r,100));
    add_chapters();
});
const add_chapters = notif.step("Add chapters", async ()=>{
    const add_chapter = await appear(".chapter_buttons input:last-child");
    await add_chapter.tte(
        "<p>Click 'Add another chapter' for recordings that contain more than one chapter.</p>",  "right", "middle", "cover", {
            click: false, 
            promise: r=>appear(".chapter_button:nth-child(2)").then(r)
        }
    ).promise;
    notif.not_from_refresh = true;
    the_end();
})
const the_end = notif.step("The end", async ()=>{
    if (notif.not_from_refresh) {   // This conditional won't be executed upon refresh
        const chapter = await appear(".chapter");
        await chapter.tte(
            "<p>The new chapter is automatically filled with the info you entered for the first one.<br>\
                <strong>Don't forget to edit this form for the second chapter</strong> if applicable!</p>\
            <p>Now reload the page to start over your report.</p>",
            "right", "middle", {
                click: false, 
                promise: r=>null    // will never complete
            }
        ).promise;
    }
})
