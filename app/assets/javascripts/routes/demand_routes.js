function getDemands(companyId, projectsIds) {
    $("#general-loader").show();

    jQuery.ajax({
        url: `/companies/${companyId}/demands/demands_in_projects.js`,
        type: "GET",
        data: `projects_ids=${projectsIds}`
    });
}

function searchDemandsByFlowStatus(companyId, projectsIds, flatDemands, groupedByMonth, groupedByCustomer, notStarted, committed, delivered, period) {
    $("#general-loader").show();

    $(".form-control").prop('disabled', true);
    $(".filter-checks").prop('disabled', true);

    jQuery.ajax({
        url: `/companies/${companyId}/demands/search_demands_by_flow_status.js`,
        type: "GET",
        data: `&flat_demands=${flatDemands}&projects_ids=${projectsIds}&grouped_by_month=${groupedByMonth}&grouped_by_customer=${groupedByCustomer}&not_started=${notStarted}&wip=${committed}&delivered=${delivered}&period=${period}`
    });
}
