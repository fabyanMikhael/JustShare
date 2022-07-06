<script lang="ts">
import { Peer } from "peerjs"
import { createEmptyAudioTrack, createEmptyVideoTrack } from "./fake";
import { copy } from "clipboard";

    var peer = new Peer()
    let viewers = 0
    let disabled = false
    let shareEnabled = false
    let ID: string = peer.id
    let joinID: string
    let notification = ""
    let video: any

    peer.on('open', id => {
            ID = id
            console.log(`connected to PeerServer!`)
            const autojoin = new URLSearchParams(window.location.search).get("autojoin");
            disabled = true;
            if (autojoin){
                console.log("found autojoin code, joining...");
                joinID = autojoin;
                join();
            }else{
                disabled = false;
            }
        }
    );
    let host = async () => {
        disabled = true;
        const ScreenData = await navigator.mediaDevices.getDisplayMedia({
                video: true,
                audio: false
        })
        video.srcObject = ScreenData;
        peer.on("call", (call) => {
            console.log(`Answering a call from ${call.connectionId}`)
            call.answer(ScreenData)
            viewers = viewers + 1
            call.on("iceStateChanged", s => {
                if (s == "disconnected"){
                    viewers = viewers - 1
                }
            });
            
        })
        shareEnabled = true
    }
    let join = async () => {     
        console.log(`joining ${joinID}`);
           
        disabled = true;
        const audioTrack = createEmptyAudioTrack();
        const videoTrack = createEmptyVideoTrack({ width:640, height:480 });
        const mediaStream = new MediaStream([audioTrack, videoTrack]);
        const call = peer.call(joinID, mediaStream);
		call.on("stream", remoteStream => {
			video.srcObject = remoteStream;
		})
        call.on("close", ()=>{
            notification = "Host has closed connection! 😢";
        });
    }


</script>


<main>
    <button on:click={host} hidden={disabled}>host</button>
    <!-- svelte-ignore a11y-media-has-caption -->
    <div>   
        <div style="width: 100%; text-align: center;">
            <button hidden={!shareEnabled} on:click={()=>copy(`${window.location.origin}?autojoin=${ID}`)}>Share | 👀 {viewers}</button>
        </div>
        <br>
        <h1>{notification}</h1>
        <video bind:this={video} autoplay style="width: 1500px" hidden={!disabled} playsinline controls></video> 
    </div>

</main>

<style>
    main {
        display: flex;
        align-content: center;
        justify-content: center;
    }
    button{
        font-size: larger;
        width: 7em;
        max-width: 10em;
        height: 2em;
        margin: 2px;
    }
    /* input{
        width: 20em;
        height: 1.5em;
        margin: 2px;
    } */
</style>