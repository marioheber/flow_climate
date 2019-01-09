$('#demands-grouped-per-month-div').hide();
$('#demands-grouped-per-customer-div').hide();

const companyId = $("#company_id").val();
const teamId = $("#team_id").val();

$('.filter-checks').on('change', function(){
    const flatDemands = $('#grouping_no_grouping').is(":checked");
    const groupedByMonth = $('#grouping_grouped_by_month').is(":checked");
    const groupedByCustomer = $('#grouping_grouped_by_customer').is(":checked");

    const notStarted = $('#searching_not_started').is(":checked");
    const committed = $('#searching_work_in_progress').is(":checked");
    const delivered = $('#searching_delivered_demands').is(":checked");

    searchDemandsByFlowStatus(companyId, teamId, flatDemands, groupedByMonth, groupedByCustomer, notStarted, committed, delivered)
});
