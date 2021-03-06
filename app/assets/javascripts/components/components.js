function accordionBehaviour() {
    const acc = document.getElementsByClassName("accordion");
    let i;

    for (i = 0; i < acc.length; i++) {
        acc[i].addEventListener("click", function() {
            this.classList.toggle("active");
            const panel = this.nextElementSibling;
            if (panel.style.display === "block") {
                panel.style.display = "none";
            } else {
                panel.style.display = "block";
            }
        });
    }
}

function openTab(evt, tabName, tabClass) {
    let i, tabcontent, subTabs;
    tabcontent = document.getElementsByClassName("tabcontent");
    for (i = 0; i < tabcontent.length; i++) {
        tabcontent[i].style.display = "none";
    }

    subTabs = document.getElementsByClassName(tabClass);
    for (i = 0; i < subTabs.length; i++) {
        subTabs[i].className = subTabs[i].className.replace(" active", "");
    }
    document.getElementById(tabName).style.display = "block";
    evt.currentTarget.className += " active";
}

function openDemandsDiv(evt, divId, inactiveDivId) {
    let i, listingTabs;
    listingTabs = document.getElementsByClassName("listing-tab");
    for (i = 0; i < listingTabs.length; i++) {
        listingTabs[i].className = listingTabs[i].className.replace(" btn-active", "");
    }

    document.getElementById(divId).style.display = "block";
    document.getElementById(inactiveDivId).style.display = "none";

    evt.currentTarget.className += " btn-active";
}

function searchWeekBehaviour() {
    $('#search-week').on('click', function () {
        const flow_div = $('#flow');
        flow_div.hide();
        $("#general-loader").show();
        searchDemandsToFlowCharts($('#company_id').val(), $('#team_id').val(), $('#week').val(), $('#year').val());
    });
}

function operationalChartsPeriodBehaviour() {
    $('#operational-charts-period').change(function(event){
        $("#general-loader").show();
        $('#operational-charts-div').hide();

        event.preventDefault();

        const companyId = $("#company_id").val();
        const period = $('#operational-charts-period').val();
        const projects_ids = $("#projects_ids").val();
        const target_name = $("#target_name").val();

        buildOperationalCharts(companyId, projects_ids, period, target_name)
    });
}

function statusReportPeriodBehaviour(){
    $('#status-report-period').on('change', function(event){
        $("#general-loader").show();
        $('#project-status-report').hide();

        event.preventDefault();

        const companyId = $("#company_id").val();
        const period = $('#status-report-period').val();
        const projects_ids = $("#projects_ids").val();
        const target_name = $("#target_name").val();

        buildStatusReportCharts(companyId, projects_ids, period, target_name);
    });
}
