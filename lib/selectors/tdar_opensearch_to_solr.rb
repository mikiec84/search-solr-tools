require './lib/selectors/helpers/iso_to_solr_format'
require './lib/selectors/helpers/tdar_format'
require './lib/selectors/helpers/solr_format'

# The hash contains keys that should map to the fields in the solr schema, the
# keys are called selectors and are in charge of selecting the nodes from the
# ISO document, applying the default value if none of the xpaths resolved to a
# value and formatting the field. xpaths and multivalue are required,
# default_value and format are optional

TDAR = {
  authoritative_id: {
    xpaths: ['.//atom:link/@href'],
    multivalue: false,
    format: proc do |node|
              'TDAR-' << node.text.split('/')[4] || ''
            end
  },
  title: {
    xpaths: ['.//atom:title'],
    multivalue: false
  },
  summary: {
    xpaths: ['.//atom:summary'],
    multivalue: false
  },
  data_centers: {
    xpaths: [''],
    default_values: [SolrFormat::DATA_CENTER_NAMES[:TDAR][:long_name]],
    multivalue: false
  },
  authors: {
    xpaths: ['.//atom:author/atom:name'],
    multivalue: true
  },
  keywords: {
    xpaths: [''],
    multivalue: true,
    format: IsoToSolrFormat::KEYWORDS
  },
  last_revision_date: {
    xpaths: ['.//atom:updated'],
    default_values: [SolrFormat.date_str(DateTime.now)], # formats the date into ISO8601 as in http://lucene.apache.org/solr/4_4_0/solr-core/org/apache/solr/schema/DateField.html
    multivalue: false,
    format: SolrFormat::DATE
  },
  dataset_url: {
    xpaths: ['.//atom:link/@href'],
    multivalue: false
  },
  spatial_coverages: {
    xpaths: ['.//georss:box'],
    multivalue: true,
    format: TdarFormat::SPATIAL_DISPLAY
  },
  spatial: {
    xpaths: ['.//georss:box'],
    multivalue: true,
    format: TdarFormat::SPATIAL_INDEX
  },
  spatial_area: {
    xpaths: ['.//georss:box'],
    multivalue: false,
    reduce: TdarFormat::MAX_SPATIAL_AREA,
    format: TdarFormat::SPATIAL_AREA
  },
  source: {
    xpaths: [''],
    default_values: ['ADE'],
    multivalue: false
  },
  facet_data_center: {
      xpaths: [''],
      default_values: ["#{SolrFormat::DATA_CENTER_NAMES[:TDAR][:long_name]} | #{SolrFormat::DATA_CENTER_NAMES[:TDAR][:short_name]}"],
      multivalue: false
  },
  facet_spatial_scope: {
    xpaths: ['.//georss:box'],
    multivalue: true,
    format: TdarFormat::FACET_SPATIAL_SCOPE
  }
}
