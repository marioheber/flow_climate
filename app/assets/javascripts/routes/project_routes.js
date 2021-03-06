function getProjectStatistics(companyId, projectId, startDate, endDate, period) {
    $("#general-loader").show();

    jQuery.ajax({
        url: `/companies/${companyId}/projects/${projectId}/statistics_tab.js`,
        type: "GET",
        data: `start_date=${startDate}&end_date=${endDate}&period=${period}`
    });
}

function getProjectBlocks(companyId, projectId, startDate, endDate) {
    $("#general-loader").show();

    jQuery.ajax({
        url: `/companies/${companyId}/projects/${projectId}/demands_blocks_tab.js`,
        type: "GET",
        data: `start_date=${startDate}&end_date=${endDate}`
    });
}
