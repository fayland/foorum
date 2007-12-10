function OnDemandJS(id, wholeurl) {
    
    if (!id || !wholeurl) return;
    
    oScript = document.getElementById(id);
    var head = document.getElementsByTagName("head").item(0);

    if (oScript) {
        // Destory object
        head.removeChild(oScript);
    }

    // Create object
    oScript = document.createElement("script");

    oScript.setAttribute("src", wholeurl);
    oScript.setAttribute("id", id);

    head.appendChild(oScript);
}