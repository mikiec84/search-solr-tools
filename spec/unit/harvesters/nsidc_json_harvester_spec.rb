require 'spec_helper'

describe SearchSolrTools::Harvesters::NsidcJson do
  bin_configuration = File.read('spec/unit/fixtures/bin_configuration.json')
  before :each do
    stub_request(:get, 'http://integration.nsidc.org/api/dataset/metadata//binConfiguration').with(headers: { Accept: '*/*; q=0.5, application/xml', 'Accept-Encoding' => 'gzip, deflate', 'User-Agent' => 'Ruby' }).to_return(status: 200, body: bin_configuration, headers: {})
    @harvester = described_class.new 'integration'
  end

  it 'should retrieve dataset identifiers from the NSIDC OAI url' do
    stub_request(:get, 'http://integration.nsidc.org/api/dataset/metadata/oai?verb=ListIdentifiers&metadata_prefix=iso')
      .with(headers: { 'Accept' => '*/*', 'User-Agent' => 'Ruby' })
      .to_return(status: 200, body: File.open('spec/unit/fixtures/nsidc_oai_identifiers.xml'))

    expect(@harvester.result_ids_from_nsidc.first.text).to eql('oai:nsidc/G02199')
  end

  describe 'Adding documents to Solr' do
    it 'constructs a hash with doc children' do
      stub_request(:get, 'http://integration.nsidc.org/api/dataset/metadata/oai?verb=ListIdentifiers&metadata_prefix=iso')
        .with(headers: { 'Accept' => '*/*', 'User-Agent' => 'Ruby' })
        .to_return(status: 200, body: File.open('spec/unit/fixtures/nsidc_oai_identifiers.xml'))

      stub_request(:get, 'http://integration.nsidc.org/api/dataset/metadata/G02199.json')
        .with(headers: { 'Accept' => '*/*; q=0.5, application/xml', 'Accept-Encoding' => 'gzip, deflate', 'User-Agent' => 'Ruby' })
        .to_return(status: 200, body: File.open('spec/unit/fixtures/nsidc_G02199.json'), headers: {})

      stub_request(:get, 'http://integration.nsidc.org/api/dataset/metadata/NSIDC-0419.json')
        .with(headers: { 'Accept' => '*/*; q=0.5, application/xml', 'Accept-Encoding' => 'gzip, deflate', 'User-Agent' => 'Ruby' })
        .to_return(status: 200, body: File.open('spec/unit/fixtures/nsidc_G02199.json'), headers: {})

      stub_request(:get, 'http://integration.nsidc.org/api/dataset/metadata/NSIDC-0582.json')
        .with(headers: { 'Accept' => '*/*; q=0.5, application/xml', 'Accept-Encoding' => 'gzip, deflate', 'User-Agent' => 'Ruby' })
        .to_return(status: 200, body: File.open('spec/unit/fixtures/nsidc_G02199.json'), headers: {})

      result = @harvester.docs_with_translated_entries_from_nsidc
      expect(result[:add_docs].first['add']['doc']['authoritative_id']).to eql('G02199')
      expect(result[:add_docs].first['add']['doc']['brokered']).to eql(false)
      expect(result[:add_docs].first['add']['doc']['dataset_version']).to eql(2)
      expect(result[:add_docs].first['add']['doc']['data_centers']).to eql('National Snow and Ice Data Center')
      expect(result[:add_docs].first['add']['doc']['published_date']).to eql('2013-01-01T00:00:00Z')
      expect(result[:add_docs].first['add']['doc']['last_revision_date']).to eql('2013-03-12T21:18:12Z')
      expect(result[:add_docs].first['add']['doc']['facet_format']).to eql([SearchSolrTools::Helpers::SolrFormat::NOT_SPECIFIED])
      expect(result[:add_docs].first['add']['doc']['data_access_urls'].first).to eql('FTP | download | http://localhost:11580/forms/G02199_or.html | Direct download, with optional registration page.')
      expect(result[:add_docs].first['add']['doc']['sponsored_programs'].first).to eql('NOAA @ NSIDC')
    end

    it 'constructs a sucessful doc children hash and an errors hash for failured ids' do
      stub_request(:get, 'http://integration.nsidc.org/api/dataset/metadata/oai?verb=ListIdentifiers&metadata_prefix=iso')
        .with(headers: { 'Accept' => '*/*', 'User-Agent' => 'Ruby' })
        .to_return(status: 200, body: File.open('spec/unit/fixtures/nsidc_oai_identifiers.xml'))

      stub_request(:get, 'http://integration.nsidc.org/api/dataset/metadata/G02199.json')
        .with(headers: { 'Accept' => '*/*; q=0.5, application/xml', 'Accept-Encoding' => 'gzip, deflate', 'User-Agent' => 'Ruby' })
        .to_return(status: 500)

      stub_request(:get, 'http://integration.nsidc.org/api/dataset/metadata/NSIDC-0419.json')
        .with(headers: { 'Accept' => '*/*; q=0.5, application/xml', 'Accept-Encoding' => 'gzip, deflate', 'User-Agent' => 'Ruby' })
        .to_return(status: 200, body: File.open('spec/unit/fixtures/nsidc_G02199.json'), headers: {})

      stub_request(:get, 'http://integration.nsidc.org/api/dataset/metadata/NSIDC-0582.json')
        .with(headers: { 'Accept' => '*/*; q=0.5, application/xml', 'Accept-Encoding' => 'gzip, deflate', 'User-Agent' => 'Ruby' })
        .to_return(status: 200, body: File.open('spec/unit/fixtures/nsidc_G02199.json'), headers: {})

      result = @harvester.docs_with_translated_entries_from_nsidc
      expect(result[:add_docs].first['add']['doc']['authoritative_id']).to eql('G02199')
      expect(result[:add_docs].length).to eql 2
      expect(result[:failure_ids].first).to eql('G02199')
      expect(result[:failure_ids].length).to eql 1
    end
  end
end
