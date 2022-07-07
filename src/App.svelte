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
</script>

<svelte:head>
    <meta property="og:title" content="JustShare" />
    <meta property="og:image" content="/favicon.ico" />
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
    <nav>
        <h1>JustShare 🍪</h1>
        <div class="buttons">
            <button on:click={host} {disabled}>host 👻</button>

            {#if videoEnabled && is_host}
                <button
                    on:click={() =>
                        copy(`${window.location.origin}?room=${ID}`)}
                    >Share
                </button>

                <h2>{viewers} 👀</h2>
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
    }

    nav {
        width: 100%;
        margin: 0;
        display: flex;
        align-items: center;
        justify-content: space-between;
    }

    .buttons {
        height: 3rem;
        align-items: center;
        display: flex;
        gap: 1rem;
    }

    main {
        height: 100%;
        margin: auto;
        padding: 0 0;
    }

    h1 {
        margin: 0;
    }

    button {
        background-color: rgb(220, 220, 220);
        border: none;
        font-size: 1.6rem;
        font-weight: 700;
        padding: 0.5rem 2rem;
        border-radius: 5px;
        cursor: pointer;
    }

    button:not(:disabled):hover {
        background-color: rgb(200, 200, 200);
    }

    button:not(:disabled):active {
        background-color: rgb(180, 180, 180);
    }

    .stream {
        margin-top: 1rem;
    }

    video {
        width: 100%;
    }

    .notif {
        text-align: center;
    }

    @media (max-width: 580px) {
        h2 {
            font-size: 1rem;
        }

        button {
            font-size: 1rem;
            padding: 0.3rem 1rem;
        }

        .buttons {
            gap: 0.5rem;
        }
    }
</style>
