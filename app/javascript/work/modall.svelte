<script>
    import { btn, cbtn, dbtn } from "./buttons"
    import ModalHeader from './modall_box_header.svelte'
    export let name;
    export let title;
    export let h;
    export let b;
    export let delegate;
    export let f;
    export let ff;
    export let btnc;
    export let icon;
    function callf(){
        if(delegate){
            delegate[f]();
        }
        else{
            ff();
        }
    }
    let btn_class = b == "DELETE" ? "btn-danger" : "btn-primary";
    let btn_class2 = b == "DELETE" ? "btn-danger" : "";
</script>

<details id={name} class="details-reset details-overlay details-overlay-dark">
    {#if icon}
        <summary class="text-center">
            <i class={icon}></i>
        </summary>
    {:else}
        <summary class="btn {btnc} {btn_class2}">
            <slot name=summary>
                Click
            </slot>
        </summary>
    {/if}
    <details-dialog class="Box Box--overlay anim-fade-in fast">
        <ModalHeader {title} />
        <div class="overflow-auto">
            <div class="Box-body overflow-auto">
                <div>
                    {h}
                </div>
                {#if $$slots.body}
                    <div>
                        <slot name=body></slot>
                    </div>
                {/if}
            </div>
        </div>
        <div class="Box-footer text-right">
            {#if $$slots.footer}
                <slot name=footer></slot>
            {:else}
                <button type="button" class="btn {btn_class}"   data-close-dialog on:click={callf}>{b}</button>
                <!-- <button type="button" class="btn btn-secondary" data-close-dialog>Cancel</button> -->
            {/if}
        </div>
    </details-dialog>
</details>
