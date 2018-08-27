# @!visibility private
class wordpress::config {

  $::wordpress::instances.each |$resource, $attributes| {
    ::wordpress::instance { $resource:
      * => $attributes,
    }
  }
}
