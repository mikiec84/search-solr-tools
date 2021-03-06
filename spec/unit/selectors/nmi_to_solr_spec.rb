require 'spec_helper'

describe 'NMI OAI to Solr converter' do
  fixture = Nokogiri.XML File.open('spec/unit/fixtures/nmi_oai.xml')
  iso_to_solr = SearchSolrTools::Helpers::IsoToSolr.new(:nmi)
  solr_doc = iso_to_solr.translate fixture

  test_expectations = [
    {
      title: 'should include the correct authoritative id',
      xpath: "/doc/field[@name='authoritative_id']",
      expected_text: 'oai:met.no:metamod/DAMOC/ecmwf'
    },
    {
      title: 'should grab the correct title',
      xpath: "/doc/field[@name='title']",
      expected_text: 'ECMWF deterministic model forecast'
    },
    {
      title: 'should grab the correct summary',
      xpath: "/doc/field[@name='summary']",
      expected_text: 'Products from the ECMWF Atmospheric Deterministic medium-range weather forecasts up to ten days. ' \
      'Check out http://www.ecmwf.int/ for details. The model output has been subsetted, reprojected and ' \
      'reformatted using FIMEX (http://wiki.met.no/fimex/).'
    },
    {
      title: 'should grab the correct data center',
      xpath: "/doc/field[@name='data_centers']",
      expected_text: 'Norwegian Meteorological Institute'
    },
    {
      title: 'should grab the correct keywords',
      xpath: "/doc/field[@name='keywords']",
      expected_text: 'LIQUID WATER EQUIVALENTHUMIDITYSEA LEVEL PRESSURESNOW WATER EQUIVALENTGEOPOTENTIAL HEIGHTPRECIPITATION AMOUNTSEA SURFACE TEMPERATUREAIR TEMPERATURELIQUID WATER EQUIVALENTCLOUD AMOUNT/FREQUENCYCLOUD AMOUNT/FREQUENCY'
    },
    {
      title: 'should grab the correct updated date',
      xpath: "/doc/field[@name='last_revision_date']",
      expected_text: '2009-11-11T00:00:00Z'
    },
    {
      title: 'should grab the correct get data link',
      xpath: "/doc/field[@name='dataset_url']",
      expected_text: 'http://thredds.met.no/thredds/catalog/data/met.no/ecmwf/'
    },
    {
      title: 'should grab the correct spatial display bounds',
      xpath: "/doc/field[@name='spatial_coverages']",
      expected_text: '60.0 -180.0 90.0 180.0'
    },
    {
      title: 'should grab the correct spatial bounds',
      xpath: "/doc/field[@name='spatial']",
      expected_text: '-180.0 60.0 180.0 90.0'
    },
    {
      title: 'should calculate the correct spatial area',
      xpath: "/doc/field[@name='spatial_area']",
      expected_text: '30.0'
    },
    {
      title: 'should grab the correct temporal coverage',
      xpath: "/doc/field[@name='temporal_coverages']",
      expected_text: '2008-06-02,2011-12-12'
    },
    {
      title: 'should grab the correct temporal range',
      xpath: "/doc/field[@name='temporal']",
      expected_text: '20.080602 20.111212'
    },
    {
      title: 'should grab the correct temporal duration',
      xpath: "/doc/field[@name='temporal_duration']",
      expected_text: '1289'
    },
    {
      title: 'should grab the correct source',
      xpath: "/doc/field[@name='source']",
      expected_text: 'ADE'
    },
    {
      title: 'should grab the correct data center facet',
      xpath: "/doc/field[@name='facet_data_center']",
      expected_text: 'Norwegian Meteorological Institute | Met.no'
    },
    {
      title: 'should grab the correct spatial scope facet',
      xpath: "/doc/field[@name='facet_spatial_scope']",
      expected_text: 'Between 1 and 170 degrees of latitude change | Regional'
    },
    {
      title: 'should grab the correct temporal duration facet',
      xpath: "/doc/field[@name='facet_temporal_duration']",
      expected_text: '1+ years'
    }
  ]

  test_expectations.each do |expectation|
    it expectation[:title] do
      expect(solr_doc.xpath(expectation[:xpath]).text.strip).to eql expectation[:expected_text]
    end
  end
end
