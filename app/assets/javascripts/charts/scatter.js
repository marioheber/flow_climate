function buildScatterChart(scatterDiv) {
    new Highcharts.Chart({
        chart: {
            type: 'scatter',
            zoomType: 'xy',
            renderTo: scatterDiv.attr('id')
        },
        title: {
            text: scatterDiv.data('title'),
            x: -20 //center
        },
        subtitle: {
            text: 'Source: Flow Climate'
        },
        xAxis: {
            title: { text: scatterDiv.data('xtitle') }
        },
        yAxis: {
            title: {
                text: scatterDiv.data('ysuffix')
            },
            plotLines: [{
                value: scatterDiv.data('percentile95'),
                color: 'green',
                dashStyle: 'shortdash',
                width: 2,
                label: {
                    style: {
                        color: 'green'
                    },
                    text: 'percentile 95% (' + scatterDiv.data('percentile95').toFixed(2) + ' ' + scatterDiv.data('ysuffix') + ')'
                }
            },{
                value: scatterDiv.data('percentile80'),
                color: 'yellow',
                dashStyle: 'shortdash',
                width: 2,
                label: {
                    style: {
                        color: 'yellow'
                    },
                    text: 'percentile 80% (' + scatterDiv.data('percentile80').toFixed(2) + ' ' + scatterDiv.data('ysuffix') + ')'
                }
            },{
                value: scatterDiv.data('percentile60'),
                color: 'red',
                dashStyle: 'shortdash',
                width: 2,
                label: {
                    style: {
                        color: 'red'
                    },
                    text: 'percentile 60% (' + scatterDiv.data('percentile60').toFixed(2) + ' ' + scatterDiv.data('ysuffix') + ')'
                }
            }]
        },
        tooltip: {
            enabled: true,
            valuePrefix: scatterDiv.data('ysuffix'),
            valueDecimals: scatterDiv.data('decimals'),
            shared: true
        },
        legend: {
            layout: 'vertical',
            align: 'right',
            verticalAlign: 'middle',
            borderWidth: 0
        },
        plotOptions: {
            scatter: {
                marker: {
                    radius: 5,
                    states: {
                        hover: {
                            enabled: true,
                            lineColor: 'rgb(100,100,100)'
                        }
                    }
                },
                states: {
                    hover: {
                        marker: {
                            enabled: false
                        }
                    }
                },
                tooltip: {
                    headerFormat: '<b>{series.name}</b><br>',
                    pointFormat: '{point.x}: {point.y:.2f} ' + scatterDiv.data('ysuffix')
                }
            }
        },
        series: scatterDiv.data('series')
    });
}