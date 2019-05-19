# @!visibility private
class wordpress::install {

  include ::php::extension::mysql
  include ::php::extension::xml
}
