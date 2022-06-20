import "./editform.scss";

import "../../assets/javascripts/nodes.js.coffee";

// Handle nested fields like task[meta][notes]
const addFormField = function(name, value){
    if (name.indexOf('[')>=0){
        let currentObject = this;
        const keys = name.split('[');
        keys.map( (subname,i) => {
            subname = subname.replace(/\]$/,'');
            if (!currentObject.hasOwnProperty(subname)) {
                if (i==keys.length-1) currentObject[subname] = value;
                else currentObject[subname] = {};
            }
            currentObject = currentObject[subname];
        });
    }
    else
        this[name] = value;
}

const sendUpdate = function(){
    let requestObject = {};
    let form = this.parentElement;
    while (form && form.nodeName != "FORM") form = form.parentElement;
    if (form!==undefined){
        addFormField.call(requestObject, this.name, this.value)
        let method = "PATCH";
        const methodInput = $(form).find("input[name='_method']");
        if (methodInput.length) method = methodInput.val() || method;
        // const params = $(form).serializeArray();
        // params.map( param => {
        //     if (param.name=="_method") method = param.value;
        //     else addFormField.call(requestObject, param.name, param.value);
        // } );
        method = method.toLowerCase();
        if (window.ldc_nodes[method])
            window.ldc_nodes[method]( form.action, requestObject, m => $(form).find("input[type='submit']").addClass("todate") );
    }
}

const checkUpdateText = function(){
    let currentVal = $(this).val();
    if (currentVal != $(this).prop("valueOnLastUpdate")){
        $(this).prop("valueOnLastUpdate", currentVal);
        sendUpdate.call(this);
    }
}

$(document).ready( ()=>{
    $("input[type='text']").keydown(function(e) {
        if (e.key=="Enter"){
            e.preventDefault();
            e.stopPropagation();
            checkUpdateText.call(this);
            return false;
        }
    });
    $("input[type='text'], textarea").each(function(){
        $(this).prop("valueOnLastUpdate", $(this).val());
    }).blur( function(e){ checkUpdateText.call(this); } )
    .keyup(function(e){
        if ($(this).val()!=$(this).prop("valueOnLastUpdate")){
            let form = this.parentElement;
            while (form && form.nodeName != "FORM") form = form.parentElement;
            if (form!==undefined) $(form).find("input[type='submit']").removeClass("todate");
        }
    });
    $("select, input[type='radio'], input[type='checkbox'], input[type='date']").change( function(e){ 
        sendUpdate.call(this);
    } );
    $("input[type='submit']").addClass("todate");
});
