require 'iso_to_solr'

describe 'EOL ISO to Solr converter' do

  fixture = Nokogiri.XML File.open('spec/unit/fixtures/eol_iso.xml')
  iso_to_solr = IsoToSolr.new(:eol)
  solr_doc = iso_to_solr.translate fixture

  test_expectations = [
    {
      title: 'should grab the correct id and normalize it',
      xpath: "/doc/field[@name='authoritative_id']",
      expected_text: 'aHR0cDovL2RhdGEuZW9sLnVjYXIuZWR1L2plZGkvY2F0YWxvZy91Y2FyLm5jYXIuZW9sLmRhdGFzZXQuMTA2XzMxMy50aHJlZGRzLnhtbCMvL3RocjpkYXRhc2V0W0BJRD0ndWNhci5uY2FyLmVvbC5kYXRhc2V0LjEwNl8zMTMnXQ'
    },
    {
      title: 'should grab the correct title',
      xpath: "/doc/field[@name='title']",
      expected_text: 'Barrow Area Remote Sensing - Brw Be Land Cover'
    },
    {
      title: 'should grab the correct summary',
      xpath: "/doc/field[@name='summary']",
      expected_text: 'Cloud free Quickbird satellite imagery was used to develop the land cover maps in this study. The dataset is composed of four multispectral (2.4m) and one panchromatic (0.6m) band. The multispectral bands were fused with the panchromatic scene' +
      ' using a Principal Components sharpening method, which characteristically maintains spatial and spectral quality (Vijayaraj et al., 2006). Ten land cover types were chosen for the land cover classification. These included seven vegetated land cover types' +
      ' identified from cluster analysis of plot level species cover data from ITEX and resampled IBP plots, bare ground, ice/snow/urban areas, and water.'
    },
    {
      title: 'should grab the correct data center',
      xpath: "/doc/field[@name='data_centers']",
      expected_text: 'UCAR/NCAR - Earth Observing Laboratory / Computing, Data, and Software Facility'
    },
    {
      title: 'should grab the correct author(s)',
      xpath: "/doc/field[@name='authors']",
      expected_text: 'Craig E. Tweedie, ctweedie AT utep dot edu'
    },
    {
      title: 'should grab the correct get data link',
      xpath: "/doc/field[@name='dataset_url']",
      expected_text: 'http://data.eol.ucar.edu/codiac/dss/id=106.313'
    },
    {
      title: 'should grab the correct updated date',
      xpath: "/doc/field[@name='last_revision_date']",
      expected_text: '2011-07-19T13:01:03Z'
    },
    {
      title: 'should grab the correct source',
      xpath: "/doc/field[@name='source']",
      expected_text: 'ADE'
    },
    {
      title: 'should grab the correct spatial display bounds',
      xpath: "/doc/field[@name='spatial_coverages']",
      expected_text: '71.275 -156.64 71.296 -156.568'
    },
    {
      title: 'should grab the correct spatial bounds',
      xpath: "/doc/field[@name='spatial']",
      expected_text: '-156.64 71.275 -156.568 71.296'
    },
    {
      title: 'should calculate the correct spatial area',
      xpath: "/doc/field[@name='spatial_area']",
      expected_text: '7591558.070440623'
    },
    {
      title: 'should grab the correct temporal coverage',
      xpath: "/doc/field[@name='temporal_coverages']",
      expected_text: '2002-08-01T00:00:00Z,2008-07-30T23:59:59Z'
    },
    {
      title: 'should grab the correct temporal duration',
      xpath: "/doc/field[@name='temporal_duration']",
      expected_text: '2191'
    },
    {
      title: 'should grab the correct temporal range',
      xpath: "/doc/field[@name='temporal']",
      expected_text: '20.020801 20.080730'
    }
  ]

  test_expectations.each do |expectation|
    it expectation[:title] do
      solr_doc.xpath(expectation[:xpath]).text.strip.should eql expectation[:expected_text]
    end
  end

end
