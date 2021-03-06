module FilterHelper
  def period_options(selected_value = :month)
    options_for_select([[I18n.t('general.filter.period.option.last_week'), 'week'], [I18n.t('general.filter.period.option.last_month'), 'month'], [I18n.t('general.filter.period.option.last_quarter'), 'quarter'], [I18n.t('general.filter.period.option.all_period'), 'all']], selected_value)
  end

  def grouping_options(selected_value = :no_grouping)
    options_for_select([[I18n.t('demands.filter.grouping.no_grouping'), :no_grouping], [I18n.t('demands.filter.grouping.grouped_by_month'), :grouped_by_month], [I18n.t('demands.filter.grouping.grouped_by_customer'), :grouped_by_customer], [I18n.t('demands.filter.grouping.grouped_by_stage'), :grouped_by_stage]], selected_value)
  end

  def flow_status_options(selected_value = :all_demands)
    options_for_select([[I18n.t('demands.filter.flow_status.all_demands'), :all_demands], [I18n.t('demands.filter.flow_status.not_started'), :not_started], [I18n.t('demands.filter.flow_status.work_in_progress'), :wip], [I18n.t('demands.filter.flow_status.delivered_demands'), :delivered]], selected_value)
  end

  def demand_type_options(selected_value = :all_types)
    options_for_select([[I18n.t('demands.filter.demand_type.all_types'), :all_types], [I18n.t('activerecord.attributes.demand.enums.demand_type.feature'), :feature], [I18n.t('activerecord.attributes.demand.enums.demand_type.bug'), :bug], [I18n.t('activerecord.attributes.demand.enums.demand_type.chore'), :chore], [I18n.t('activerecord.attributes.demand.enums.demand_type.performance_improvement'), :performance_improvement], [I18n.t('activerecord.attributes.demand.enums.demand_type.ui'), :ui], [I18n.t('activerecord.attributes.demand.enums.demand_type.wireframe'), :wireframe]], selected_value)
  end

  def class_of_service_options(selected_value = :all_classes)
    options_for_select([[I18n.t('demands.filter.class_of_service.all_classes'), :all_classes], [I18n.t('activerecord.attributes.demand.enums.class_of_service.standard'), :standard], [I18n.t('activerecord.attributes.demand.enums.class_of_service.expedite'), :expedite], [I18n.t('activerecord.attributes.demand.enums.class_of_service.fixed_date'), :fixed_date], [I18n.t('activerecord.attributes.demand.enums.class_of_service.intangible'), :intangible]], selected_value)
  end

  def grouping_period_to_charts_options(selected_value = :week)
    options_for_select([[I18n.t('general.filter.grouping_period.option.day'), 'day'], [I18n.t('general.filter.grouping_period.option.week'), 'week'], [I18n.t('general.filter.grouping_period.option.month'), 'month'], [I18n.t('general.filter.grouping_period.option.year'), 'year'] ], selected_value)
  end
end
