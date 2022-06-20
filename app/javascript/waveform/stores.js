import { writable } from 'svelte/store'
const segments = writable([]);
const undefined_segments = writable([]);
const sections = writable([]);
const spectrogram_settings = writable({});
const active_channel = writable(0);
const active_docid = writable(null);
export {
    segments,
    undefined_segments,
    sections,
    spectrogram_settings,
    active_docid,
    active_channel
}
