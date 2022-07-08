<script lang="ts">
    import { Peer } from "peerjs";
    import { createEmptyAudioTrack, createEmptyVideoTrack } from "./fake";
    import { copy } from "clipboard";

    var peer = new Peer();
    let viewers = 0;
    let disabled = false;
    let videoEnabled = false;
    let ID: string = peer.id;
    let joinID: string;
    let notification = "click host to start sharing 🪖";
    let video: any;
    let is_host = false;

    disabled = true;
    peer.on("open", (id) => {
        ID = id;
        console.log(`connected to PeerServer!`);
        const room = new URLSearchParams(window.location.search).get("room");
        if (room) {
            console.log("found room code, joining...");
            joinID = room;
            window.history.replaceState(
                {},
                document.title,
                window.location.pathname
            );
            join();
        } else {
            disabled = false;
        }
    });
    let host = async () => {
        notification = "";
        disabled = true;
        let ScreenData: any;
        try {
            ScreenData = await navigator.mediaDevices.getDisplayMedia({
                video: true,
                audio: true,
            });
            videoEnabled = true;
        } catch (error) {
            notification = "Could not get screen data";
            return;
        }

        video.srcObject = ScreenData;
        is_host = true;
        peer.on("call", (call) => {
            console.log(`Answering a call from ${call.connectionId}`);
            call.answer(ScreenData);
            viewers = viewers + 1;
            call.on("iceStateChanged", (s) => {
                if (s == "disconnected") {
                    viewers = viewers - 1;
                }
            });
        });
    };
    let join = async () => {
        notification = "";
        console.log(`joining ${joinID}`);

        disabled = true;
        const audioTrack = createEmptyAudioTrack();
        const videoTrack = createEmptyVideoTrack({ width: 640, height: 480 });
        const mediaStream = new MediaStream([audioTrack, videoTrack]);
        const call = peer.call(joinID, mediaStream);
        call.on("stream", (remoteStream) => {
            video.srcObject = remoteStream;
        });
        notification = "🎞️ Joining... ";
        setTimeout(() => {
            if (!videoEnabled) {
                call.close();
                notification = `Timed out! 🤔 Host could not be found`;
            }
        }, 2000);

        call.on("iceStateChanged", (s) => {
            notification = "";
            if (s == "disconnected" || s == "closed") {
                notification = "Host has closed the connection! 😢";
                videoEnabled = false;
            }
            if (s == "failed") {
                notification = `Failed to connect to host! 🤔 you sure this is the right ID? ${joinID}`;
                videoEnabled = false;
            }
            if (s == "connected" || s == "completed") {
                videoEnabled = true;
            }
        });
    };

    import { theme } from "./stores";

    if ($theme === "dark") {
        window.document.body.classList.toggle("dark-mode");
    }
    function toggle() {
        if ($theme === "light") {
            theme.set("dark");
        } else {
            theme.set("light");
        }
        window.document.body.classList.toggle("dark-mode");
    }

    let darken = false;
    $: dark = darken && videoEnabled;
</script>

<svelte:head>
    <meta property="og:title" content="JustShare" />
    <!-- <meta property="og:image" content="/favicon.ico" /> -->
    <meta
        property="og:description"
        content="Share your screen directly to anyone you want"
    />
    <meta property="og:type" content="website" />
    <meta name="theme-color" content="#53c3d4" />

    <link rel="icon" href="/favicon.ico" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />

    <title>JustShare</title>
</svelte:head>

<main>
    {#if dark}
        <div
            on:click={() => {
                darken = false;
            }}
            id="overlay"
        />
    {/if}
    <nav>
        <h1>JustShare 🍪</h1>
        <div class="buttons">
            <button on:click={toggle} class="theme"
                >{$theme == "light" ? "🌚" : "🌞"}</button
            >

            {#if videoEnabled && is_host}
                <button
                    on:click={() => {
                        darken = true;
                    }}
                    class="theme"
                    hidden={!videoEnabled}>💡</button
                >
                {#if is_host}
                    <button
                        on:click={() =>
                            copy(`${window.location.origin}?room=${ID}`)}
                        >Share
                    </button>
                    <h2 class="viewers">{viewers} 👀</h2>
                {/if}
            {:else}
                <button on:click={host} {disabled}>host 👻</button>
            {/if}
        </div>
    </nav>

    {#if notification}
        <h2 class="notif">{notification}</h2>
    {/if}

    <!-- svelte-ignore a11y-media-has-caption -->
    <div class="stream">
        <video
            bind:this={video}
            controls
            autoplay
            playsinline
            hidden={!videoEnabled}
        />
    </div>
</main>

<style>
    * {
        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto,
            Oxygen, Ubuntu, Cantarell, "Open Sans", "Helvetica Neue", sans-serif;
        /* outline: lawngreen solid 1px; */
        color: var(--text);
        transition: all 100ms;
    }

    #overlay {
        background-color: rgba(0, 0, 0, 0.8);
        position: fixed;
        left: 0;
        top: 0;
        width: 100%;
        height: 100%;
    }

    :root {
        --bg-light: #fafafa;
        --bg-dark: #1a1a1a;
        --text-light: #1a1a1a;
        --text-dark: #fafafa;

        --button-dark: #1a1a1ac0;
        --button-dark-hover: #121212;
        --button-dark-active: #000000;

        --button-light: #fafafac0;
        --button-light-hover: #fafafa;
        --button-light-active: #fafafa;

        --accent: #53c3d4;
        --accent-dark: #c4f7ff;
        --bg: var(--bg-light);
        --text: var(--text-light);

        --button: var(--button-light);
        --button-hover: var(--button-light-hover);
        --button-active: var(--button-light-active);
    }

    :global(body.dark-mode) {
        --bg: var(--bg-dark);
        --text: var(--text-dark);
        --button: var(--button-dark);
        --button-hover: var(--button-dark-hover);
        --button-active: var(--button-dark-active);
    }

    nav {
        margin: 0;
        padding: 0.5rem 0.5rem;
        display: flex;
        align-items: center;
        justify-content: space-between;

        background-color: var(--accent);
    }

    .buttons {
        height: 3rem;
        align-items: center;
        display: flex;
        gap: 0.2rem;
    }

    main {
        height: 100%;
        margin: 0;
        padding: 0;
    }

    h1 {
        margin: 0;
        padding: 0.5rem;
        color: var(--accent-dark);
    }

    button {
        background-color: var(--button);
        border: none;
        font-size: 1.3rem;
        font-weight: 700;
        padding: 0.5rem 2rem;
        border-radius: 5px;
        cursor: pointer;
        margin: 0;
        height: 3rem;
    }

    button:disabled {
        opacity: 50%;
        cursor: not-allowed;
    }

    button:not(:disabled):hover {
        background-color: var(--button-hover);
    }

    button:not(:disabled):active {
        background-color: var(--button-active);
    }

    .theme {
        padding: 0.5rem 0.8rem;
    }

    .stream {
        margin-top: 1rem;
        overflow: hidden;
        border-radius: 5px;
        position: absolute;
        z-index: 20;
    }

    video {
        width: 100%;
    }

    .notif {
        margin-top: 5rem;
        text-align: center;
    }

    .viewers {
        padding: 0 0.8rem;
    }

    @media (max-width: 580px) {
        h1 {
            font-size: 1rem;
        }

        h2 {
            font-size: 1rem;
        }

        button {
            font-size: 1rem;
            padding: 0.3rem 1rem;
            height: 2.5rem;
        }

        .theme {
            padding: 0.3rem 0.5rem;
        }
    }
</style>
