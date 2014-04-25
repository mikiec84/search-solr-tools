require 'nokogiri'
require './lib/selectors/helpers/solr_format'

describe 'SOLR format methods' do
  fixture = Nokogiri.XML File.open('spec/unit/fixtures/nsidc_iso.xml')

  describe 'date' do
    it 'should generate a SOLR readable ISO 8601 string using the DATE helper' do
      SolrFormat::DATE.call(fixture.xpath('.//gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:date/gco:Date')).should eql '2004-05-10T00:00:00Z'
    end

    it 'should generate a SOLR readable ISO 8601 string from a date obect' do
      SolrFormat.date_str(DateTime.new(2013, 1, 1)).should eql '2013-01-01T00:00:00Z'
    end

    it 'should generate a SOLR readable ISO 8601 string from a string' do
      SolrFormat.date_str('2013-01-01').should eql '2013-01-01T00:00:00Z'
    end

    it 'should generate a SOLR readable ISO 8601 string string with extra spaces' do
      SolrFormat.date_str('    2013-01-01 ').should eql '2013-01-01T00:00:00Z'
    end
  end

  describe 'temporal' do
    it 'should use only the maximum duration when a dataset has multiple temporal ranges' do
      durations = [27, 123, 325, 234, 19_032, 3]
      SolrFormat.reduce_temporal_duration(durations).should eql 19_032
    end
  end

  describe 'facets' do
    it 'should set the parameter for a variable level_1' do
      node = fixture.xpath('.//gmd:MD_Keywords[.//gmd:MD_KeywordTypeCode="discipline"]//gmd:keyword/gco:CharacterString')[0].text
      SolrFormat.parameter_binning(node).should eql 'Ice Extent'
    end

    it 'should bin the parameter' do
      node = fixture.xpath('.//gmd:MD_Keywords[.//gmd:MD_KeywordTypeCode="discipline"]//gmd:keyword/gco:CharacterString')[1].text
      SolrFormat.parameter_binning(node).should eql 'Ocean Properties (other)'
    end

    it 'should not set parameters that do not have variable level_1' do
      node = fixture.xpath('.//gmd:MD_Keywords[.//gmd:MD_KeywordTypeCode="discipline"]//gmd:keyword/gco:CharacterString')[2].text
      SolrFormat.parameter_binning(node).should eql nil
    end

    it 'should set the data format' do
      node = fixture.xpath('.//gmd:distributionFormat/gmd:MD_Format/gmd:name/gco:CharacterString')[0].text
      SolrFormat.format_binning(node).should eql 'HTML'
    end

    it 'should bin the data format' do
      node = fixture.xpath('.//gmd:distributionFormat/gmd:MD_Format/gmd:name/gco:CharacterString')[1].text
      SolrFormat.format_binning(node).should eql 'ASCII Text'
    end

    it 'should not set excluded data formats' do
      node = fixture.xpath('.//gmd:distributionFormat/gmd:MD_Format/gmd:name/gco:CharacterString')[2].text
      SolrFormat.format_binning(node).should eql nil
    end

    describe 'temporal resolution facet' do
      it 'bins second and 59 minute values as Subhourly' do
        SolrFormat.temporal_resolution_value('type' => 'single', 'resolution' => 'PT1S').should eql 'Subhourly'
        SolrFormat.temporal_resolution_value('type' => 'single', 'resolution' => 'PT59M59S').should eql 'Subhourly'
      end

      it 'bins 1 hour value as Hourly' do
        SolrFormat.temporal_resolution_value('type' => 'single', 'resolution' => 'PT60M').should eql 'Hourly'
      end

      it 'bins 1:00:01 and 23:59:59 values as Subdaily' do
        SolrFormat.temporal_resolution_value('type' => 'single', 'resolution' => 'PT1H0M1S').should eql 'Subdaily'
        SolrFormat.temporal_resolution_value('type' => 'single', 'resolution' => 'PT23H59M59S').should eql 'Subdaily'
      end

      it 'bins 1 and 2 day as Daily' do
        SolrFormat.temporal_resolution_value('type' => 'single', 'resolution' => 'P1D').should eql 'Daily'
        SolrFormat.temporal_resolution_value('type' => 'single', 'resolution' => 'P2D').should eql 'Daily'
        SolrFormat.temporal_resolution_value('type' => 'single', 'resolution' => 'P1DT12H').should eql 'Daily'
      end

      it 'bins 3 and 8 days as Weekly' do
        SolrFormat.temporal_resolution_value('type' => 'single', 'resolution' => 'P3D').should eql 'Weekly'
        SolrFormat.temporal_resolution_value('type' => 'single', 'resolution' => 'P8D').should eql 'Weekly'
      end

      it 'bins 9 and 20 days as Submonthly' do
        SolrFormat.temporal_resolution_value('type' => 'single', 'resolution' => 'P9D').should eql 'Submonthly'
        SolrFormat.temporal_resolution_value('type' => 'single', 'resolution' => 'P20D').should eql 'Submonthly'
      end

      it 'bins 1 month, 21 days and 31 days as Monthly' do
        SolrFormat.temporal_resolution_value('type' => 'single', 'resolution' => 'P1M').should eql 'Monthly'
        SolrFormat.temporal_resolution_value('type' => 'single', 'resolution' => 'P21D').should eql 'Monthly'
        SolrFormat.temporal_resolution_value('type' => 'single', 'resolution' => 'P31D').should eql 'Monthly'
      end

      it 'bins values less then 1 year as Subyearly' do
        SolrFormat.temporal_resolution_value('type' => 'single', 'resolution' => 'P364D').should eql 'Subyearly'
        SolrFormat.temporal_resolution_value('type' => 'single', 'resolution' => 'P11M').should eql 'Subyearly'
        SolrFormat.temporal_resolution_value('type' => 'single', 'resolution' => 'P3M').should eql 'Subyearly'
      end

      it 'bins 1 year as Yearly' do
        SolrFormat.temporal_resolution_value('type' => 'single', 'resolution' => 'P1Y').should eql 'Yearly'
      end

      it 'bins values greater then 1 year as Multiyearly' do
        SolrFormat.temporal_resolution_value('type' => 'single', 'resolution' => 'P2Y').should eql 'Multiyearly'
        SolrFormat.temporal_resolution_value('type' => 'single', 'resolution' => 'P30Y').should eql 'Multiyearly'
        SolrFormat.temporal_resolution_value('type' => 'single', 'resolution' => 'P1Y1D').should eql 'Multiyearly'
        SolrFormat.temporal_resolution_value('type' => 'single', 'resolution' => 'P13M').should eql 'Multiyearly'
      end

      it 'bins range as range of facet values' do
        SolrFormat.temporal_resolution_value('type' => 'range', 'min_resolution' => 'PT3H', 'max_resolution' => 'P10D')
        .should eql %w(Subdaily Daily Weekly Submonthly)
      end

      it 'bins varies as varies' do
        SolrFormat.temporal_resolution_value('type' => 'varies').should eql SolrFormat::NOT_SPECIFIED
      end

      it 'returns not specified if the value is blank' do
        SolrFormat.temporal_resolution_value('type' => 'single', 'resolution' => '').should eql SolrFormat::NOT_SPECIFIED
        SolrFormat.temporal_resolution_value('type' => 'range', 'min_resolution' => '', 'max_resolution' => '').should eql SolrFormat::NOT_SPECIFIED
      end
    end

    describe 'spatial resolution facet' do
      value_bins = { '0 - 500 m' => ['1 m', '500 m'],
                     '501 m - 1 km' => ['501 m', '1000 m'],
                     '2 - 5 km' => ['1001 m', '5000 m', '0.01 deg', '0.05 deg'],
                     '6 - 15 km' => ['5001 m', '15000 m'],
                     '16 - 30 km' => ['15001 m', '30000 m', '0.06 deg', '0.25 deg', '0.49 deg'],
                     '>30 km' => ['30001 m', '100000 m', '0.5 deg', '1 deg', '5 deg'] }
      value_bins.each do |bin, values|
        values.each do |val|
          it "bins #{val} as #{bin}" do
            SolrFormat.spatial_resolution_value('type' => 'single', 'resolution' => val).should eql bin
          end
        end
      end
    end
  end
end
