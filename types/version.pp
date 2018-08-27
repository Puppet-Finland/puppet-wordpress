# @since 0.0.1
type Wordpress::Version = Variant[Enum['latest'], Pattern[/^\d+(\.\d+){1,2}$/]]
