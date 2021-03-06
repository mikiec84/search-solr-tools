require 'spec_helper'

describe SearchSolrTools::Harvesters::Base do
  describe '#sanitize_data_centers_constraints' do
    it 'Removes all lucene chars' do
      test_string = '1+ 2  -  3&&  4| 5|6!7 8(  9)   10  11{ 12} 13[ 14]15 '\
                    '16+  ^17   ~18  *19  ?  20:    21'
      expect(described_class.new.sanitize_data_centers_constraints(test_string)).to eql [*1...22].join(' ')
    end

    it 'Retains the data_centers query seperator' do
      test_string = 'data_centers:"one| {} two [three]"'
      expect(described_class.new.sanitize_data_centers_constraints(test_string)).to eql('data_centers:"one two three "')
    end
  end

  describe 'Initialization' do
    it 'Uses a default environment if not specified' do
      harvester = described_class.new
      expect(harvester.environment).to eq('development')
    end

    it 'Initializes with a specific environment name' do
      harvester = described_class.new('qa')
      expect(harvester.environment).to eq('qa')
    end
  end

  describe '#get_results' do
    describe 'with @die_on_failure ' do
      let(:described_object) { described_class.new('development', true) }

      def described_method(request_url, metadata_path, content_type = 'application/xml')
        described_object.get_results(request_url, metadata_path, content_type)
      end

      describe 'with a successful response' do
        let(:nokogiri) { double(Nokogiri) }
        let(:doc) { double('doc') }
        let(:parsed_metadata) { double('parsed_metadata') }

        before(:each) do
          response = double('response')
          allow(described_object).to receive(:open).and_return(response)
          allow(nokogiri).to receive(:XML).and_return(doc)
          allow(doc).to receive(:xpath).and_return(parsed_metadata)
        end

        it 'returns metadata from the XML response' do
          expect do
            described_method(
              'http://www.polardata.ca/oai/provider?verb=ListRecords&metadataPrefix=iso',
              '/metadata/xpath'
            ).to eql(parsed_metadata)
          end
        end
      end

      describe 'with error OpenURI::HTTPError' do
        before(:each) do
          exception_io = double('io')
          exception_io.stub_chain(:status, :[]).with(0).and_return('302')

          allow(described_object).to receive(:open).and_raise(OpenURI::HTTPError.new('', exception_io))
        end

        it 'makes 3 attempts before propagating the error' do
          expect(described_object).to receive(:open).exactly(3).times
          expect do
            described_method(
              'http://www.polardata.ca/oai/provider?verb=ListRecords&metadataPrefix=iso',
              '/metadata/xpath'
            )
          end.to raise_error(OpenURI::HTTPError)
        end
      end

      [Timeout::Error, Errno::ETIMEDOUT].each do |err_type|
        describe "with error #{err_type}" do
          before(:each) do
            allow(described_object).to receive(:open).and_raise(err_type)
          end

          it 'makes 3 attempts before propagating the error' do
            expect(described_object).to receive(:open).exactly(3).times
            expect do
              described_method(
                'http://www.polardata.ca/oai/provider?verb=ListRecords&metadataPrefix=iso',
                '/metadata/xpath'
              )
            end.to raise_error(err_type)
          end
        end
      end
    end
  end

  it 'Builds a new Nokogiri XML document with an "add" root node' do
    doc = described_class.new.create_new_solr_add_doc
    expect(doc.root.name).to eql('add')
    expect(doc.to_xml).to eql("<?xml version=\"1.0\"?>\n<add/>\n")
  end

  it 'serializes a hash and adds it to solr in JSON format' do
    harvester = described_class.new 'integration'
    add_doc = { 'add' => { 'doc' => { 'authoritative_id' => 'TEST-0001' } } }
    serialized_add_doc = '{"add":{"doc":{"authoritative_id":"TEST-0001"}}}'

    stub_request(:post, 'http://integration.search-solr.apps.int.nsidc.org:8983/solr/nsidc_oai/update?commit=true')
      .with(body: serialized_add_doc,
            headers: { 'Accept'          => '*/*; q=0.5, application/xml',
                       'Accept-Encoding' => 'gzip, deflate',
                       'Content-Length'  => '48',
                       'Content-Type'    => described_class::JSON_CONTENT_TYPE,
                       'User-Agent'      => 'Ruby' })
      .to_return(status: 200, body: 'success', headers: {})

    expect(harvester.insert_solr_doc(add_doc, described_class::JSON_CONTENT_TYPE)).to eql(true)
  end

  it 'serializes an XML add document and adds it to solr in XML format' do
    harvester = described_class.new 'integration'
    add_doc = Nokogiri.XML('<add><doc><field name="authoritative_id">TEST-0001</field></doc></add>')
    stub_request(:post, 'http://integration.search-solr.apps.int.nsidc.org:8983/solr/nsidc_oai/update?commit=true')
      .with(body: add_doc.to_xml,
            headers: { 'Accept'          => '*/*; q=0.5, application/xml',
                       'Accept-Encoding' => 'gzip, deflate',
                       'Content-Length'  => '105',
                       'Content-Type'    => described_class::XML_CONTENT_TYPE,
                       'User-Agent'      => 'Ruby' })
      .to_return(status: 200, body: 'success', headers: {})

    expect(harvester.insert_solr_doc(add_doc)).to eql(true)
  end

  describe 'harvest_and_delete' do
    before :each do
      @harvester = described_class.new 'integration'
      expect(@harvester).to receive(:harvest).at_least(:once)
    end

    it 'adds documents and then deletes documents that were not updated' do
      stubs = stub_update_and_delete(500, 10)
      @harvester.harvest_and_delete(@harvester.method(:harvest), 'data_centers:"test"')

      expect(stubs[:delete_stub]).to have_been_requested
      expect(stubs[:commit_stub]).to have_been_requested
    end

    it 'Does not delete documents when more then .1 of documents are not updated' do
      stubs = stub_update_and_delete(500, 75)
      @harvester.harvest_and_delete(@harvester.method(:harvest), 'data_centers:"test"')

      expect(stubs[:delete_stub]).to_not have_been_requested
      expect(stubs[:commit_stub]).to_not have_been_requested
    end

    it 'Does not delete documents when none exist' do
      stubs = stub_update_and_delete(0, 0)
      @harvester.harvest_and_delete(@harvester.method(:harvest), 'data_centers:"test"')

      expect(stubs[:delete_stub]).to_not have_been_requested
      expect(stubs[:commit_stub]).to_not have_been_requested
    end
  end

  describe 'delete_old_documents' do
    before :each do
      @harvester = described_class.new 'integration'
    end

    it 'Can be forced to delete with a timestamp' do
      stubs = stub_update_and_delete(500, 75)
      @harvester.delete_old_documents('20040202', 'data_centers:"test"', SearchSolrTools::SolrEnvironments[@harvester
.environment][:collection_name], true)

      expect(stubs[:delete_stub]).to have_been_requested
      expect(stubs[:commit_stub]).to have_been_requested
    end
  end

  describe 'insert_solr_docs' do
    it 'raises an error if some documents are not successfully added' do
      harvester = described_class.new 'integration'
      allow(harvester).to receive('insert_solr_doc').and_return(false, true)

      expect { harvester.insert_solr_docs(%w(doc1 doc2 doc3)) }.to raise_error
    end
  end

  def get_response(found_count)
    "{'responseHeader'=>{'status'=>0,'QTime'=>7,'params'=>{'q'=>'data_centers:\"test\"','wt'=>'ruby','rows'=>'0'}},'response'=>{'numFound'=>#{found_count},'start'=>0,'docs'=>[]}}"
  end

  def stub_update_and_delete(all_count, not_updated_count)
    all_response = get_response(all_count)
    updated_response = get_response(not_updated_count)

    stub_request(:get, 'http://integration.search-solr.apps.int.nsidc.org:8983/solr/nsidc_oai/select?q=data_centers:%22test%22&rows=0&wt=ruby')
      .to_return(status: 200, body: all_response, headers: {})
    stub_request(:get, %r{http:\/\/integration.search-solr.apps.int.nsidc.org:8983\/solr\/nsidc_oai\/select\?q=last_update:.*AND%20data_centers:%22test%22&rows=0&wt=ruby})
      .to_return(status: 200, body: updated_response, headers: {})
    delete_stub = stub_request(:post, 'http://integration.search-solr.apps.int.nsidc.org:8983/solr/nsidc_oai/update?wt=ruby')
                  .with(body:    %r{<\?xml version="1.0" encoding="UTF-8"\?><delete><query>last_update:.* AND data_centers:"test"</query></delete>},
                        headers: { 'Content-Type' => 'text/xml' })
                  .to_return(status: 200, body: '', headers: {})
    commit_stub = stub_request(:post, 'http://integration.search-solr.apps.int.nsidc.org:8983/solr/nsidc_oai/update?wt=ruby')
                  .with(body:    '<?xml version="1.0" encoding="UTF-8"?><commit/>',
                        headers: { 'Content-Type' => 'text/xml' })
                  .to_return(status: 200, body: '', headers: {})

    { delete_stub: delete_stub, commit_stub: commit_stub }
  end

  describe '#valid_solr_spatial_coverage?' do
    def described_method(north: nil, east: nil, south: nil, west: nil)
      @harvester.valid_solr_spatial_coverage?([north, east, south, west])
    end

    before :each do
      @harvester = described_class.new
    end

    describe 'non-polar points' do
      it 'returns true for a random point' do
        expect(described_method(north: 4, east: 4, south: 4, west: 4)).to eql(true)
      end

      it 'returns true for a line running east-west' do
        expect(described_method(north: 0, east: 5, south: 0, west: 0)).to eql(true)
      end

      it 'returns true for a line running north-south' do
        expect(described_method(north: 5, east: 0, south: 0, west: 0)).to eql(true)
      end

      it 'returns true for a normal bounding box' do
        expect(described_method(north: 5, east: 5, south: 0, west: 0)).to eql(true)
      end
    end

    describe 'the north pole' do
      it 'returns true if east and west are equal' do
        expect(described_method(north: 90, east: 45, south: 90, west: 45)).to eql(true)
      end

      it 'returns false if east and west are not equal' do
        expect(described_method(north: 90, east: -45, south: 90, west: 45)).to eql(false)
      end
    end

    describe 'the south pole' do
      it 'returns true if east and west are equal' do
        expect(described_method(north: -90, east: 45, south: -90, west: 45)).to eql(true)
      end

      it 'returns false if east and west are not equal' do
        expect(described_method(north: -90, east: -45, south: -90, west: 45)).to eql(false)
      end
    end
  end
end
