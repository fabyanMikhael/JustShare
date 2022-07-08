import { writable } from "svelte/store";

const stored_theme = localStorage.getItem("theme") || "light";
export const theme = writable(stored_theme);

theme.subscribe((value) => {
    localStorage.setItem("theme", value)
});