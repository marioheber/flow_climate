hideAllComponents();
$('#team-stamps').show();
$('#nav-item-stamps').addClass('active');

$('#nav-item-stamps').on('click', function(){
    hideAllComponents();
    $('#team-stamps').show();
    $('#nav-item-stamps').addClass('active');
});

$('#nav-item-results').on('click', function(){
    hideAllComponents();
    $('#project-list').show();
    $('#nav-item-list').addClass('active');
});

$('#nav-item-charts').on('click', function(){
    hideAllComponents();
    $('#team-charts').show();
    $('#nav-item-charts').addClass('active');
});

$('#nav-item-members').on('click', function(){
    hideAllComponents();
    $('#members-table').show();
    $('#nav-item-members').addClass('active');
});

function hideAllComponents() {
    $('#team-stamps').hide();
    $('#project-list').hide();
    $('#members-table').hide();
    $('#team-charts').hide();

    $('#nav-item-stamps').removeClass('active');
    $('#nav-item-list').removeClass('active');
    $('#nav-item-charts').removeClass('active');
    $('#nav-item-members').removeClass('active');
}
;
