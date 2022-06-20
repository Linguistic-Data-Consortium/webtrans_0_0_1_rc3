<script>
    import { btn, cbtn, dbtn } from "./buttons"
    export let name;
    export let title;
    export let h;
    export let b;
    export let delegate;
    export let f;
    export let ff;
    function callf(){
        if(delegate){
            delegate[f]();
        }
        else{
            ff();
        }
    }
</script>

<details id={name} class="details-reset details-overlay details-overlay-dark">
    <summary class="btn btn-danger float-right mx-2" title="Delete Selected">
        <i class="fa fa-trash"></i>
    </summary>
    <details-dialog class="Box Box--overlay anim-fade-in fast">
        <div class="Box-header">
            <button class="Box-btn-octicon btn-octicon float-right" type="button" aria-label="Close dialog" data-close-dialog>
                <!-- <%= octicon "x" %> -->
                <i class="fa fa-times"></i>
            </button>
            <h3 class="Box-title">{title}</h3>
        </div>
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
            <button type="button" class="{btn}"   data-close-dialog on:click={callf}>{b}</button>
            <button type="button" class="btn btn-secondary" data-close-dialog>Cancel</button>
        </div>
    </details-dialog>
</details>
