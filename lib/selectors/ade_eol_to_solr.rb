require './lib/selectors/iso_to_solr_format'

# The hash contains keys that should map to the fields in the solr schema, the keys are called selectors
# and are in charge of selecting the nodes from the ISO document, applying the default value if none of the
# xpaths resolved to a value and formatting the field.
# xpaths and multivalue are required, default_value and format are optional.

EOL = {
  authoritative_id: {
      xpaths: ['.//gmd:fileIdentifier/gco:CharacterString'],
      multivalue: false,
      format: proc do | node| # double equals in the ID is "breaking" the harvest in liquid/qa etc.
                node.text.split('==')[0] || ''
              end
  },
  title: {
      xpaths: ['.//gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:title/gco:CharacterString'],
      multivalue: false
  },
  summary: {
      xpaths: ['.//gmd:identificationInfo/gmd:MD_DataIdentification/gmd:abstract/gco:CharacterString'],
      multivalue: false
  },
  data_centers: {
      xpaths: ['.//gmd:identificationInfo/gmd:MD_DataIdentification/gmd:pointOfContact/gmd:CI_ResponsibleParty/gmd:organisationName/gco:CharacterString'],
      default_values: ['UCAR/NCAR - Earth Observing Laboratory / Computing, Data, and Software Facility'],
      multivalue: false
  },
  authors: {
      xpaths: ['.//gmd:identificationInfo/gmd:MD_DataIdentification/gmd:pointOfContact/gmd:CI_ResponsibleParty'],
      multivalue: true,
      format: proc do |node|
                matches = node.xpath('./gmd:role/gmd:CI_RoleCode').attribute('codeListValue').to_s.include?('author')
                matches ? node.xpath('./gmd:organisationName/gco:CharacterString') : ''
              end
  },
  keywords: {
      xpaths: ['.//gmd:keyword/gco:CharacterString'],
      multivalue: true
  },
  last_revision_date: {
      xpaths: ['//gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:date/gco:Date', '//gmd:dateStamp'],
      default_values: [IsoToSolrFormat.date_str(DateTime.now)], # formats the date into ISO8601 as in http://lucene.apache.org/solr/4_4_0/solr-core/org/apache/solr/schema/DateField.html
      multivalue: false,
      format: IsoToSolrFormat::DATE
  },
  spatial_coverages: {
      xpaths: ['.//gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:geographicElement/gmd:EX_GeographicBoundingBox'],
      multivalue: true,
      format: proc { |node| IsoToSolrFormat.spatial_display_str node }
  },
  spatial: {
      xpaths: ['.//gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:geographicElement/gmd:EX_GeographicBoundingBox'],
      multivalue: true,
      format: IsoToSolrFormat::SPATIAL_INDEX
  },
  dataset_url: {
      xpaths: ['.//gmd:identificationInfo/gmd:MD_DataIdentification/gmd:supplementalInformation/gco:CharacterString'],
      multivalue: false,
      format: proc do |node|
                matches = node.text.match('http://data.eol.ucar.edu/codiac/dss/id=(\S*)')
                matches ? matches[0] : ''
              end
  },
  temporal_coverages: {
    xpaths: ['.//gmd:EX_TemporalExtent'],
    multivalue: true,
    format: proc { |node| IsoToSolrFormat.temporal_display_str node }
  },
  temporal: {
    xpaths: ['.//gmd:EX_TemporalExtent'],
    multivalue: true,
    format: proc { |node| IsoToSolrFormat.temporal_index_str node }
  },
  resource_origin: {
      xpaths: [''],
      default_values: ['UCAR/NCAR - Earth Observing Laboratory / Computing, Data, and Software Facility'],
      multivalue: false
  },
  source: {
      xpaths: [''],
      default_values: ['ADE'],
      multivalue: false
  },
}
