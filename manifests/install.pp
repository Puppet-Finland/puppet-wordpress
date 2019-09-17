# @!visibility private
class wordpress::install {

  if $::wordpress::manage_php {
    include ::php::extension::mysql
    include ::php::extension::xml
  }
}
