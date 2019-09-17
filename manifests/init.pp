# Manage Wordpress installations.
#
# @example Declaring the class
#   include ::wordpress
#
# @param instances
#
# @see puppet_defined_types::wordpress::instance ::wordpress::instance
#
# @since 1.0.0
class wordpress (
  Boolean                         $manage_php = true,
  Hash[String, Hash[String, Any]] $instances = {},
) {

  contain ::wordpress::install
  contain ::wordpress::config

  Class['::wordpress::install'] -> Class['::wordpress::config']
}
