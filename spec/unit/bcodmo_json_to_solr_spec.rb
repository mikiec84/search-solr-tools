require 'selectors/bcodmo_json_to_solr'

describe BcodmoJsonToSolr do
  before :each do
    @translator = described_class.new
  end

  it 'translates the dataset_deployment_version_date to solr last revision date' do
    @translator.translate_last_revision_date('2008-08-20').should eql('2008-08-20T00:00:00Z')
    @translator.translate_last_revision_date('2013-01-01 12:00:00').should eql('2013-01-01T12:00:00Z')
  end

  it 'returns nil on dataset_deployment_version_date empty values' do
    @translator.translate_last_revision_date('').should eql nil
    @translator.translate_last_revision_date(nil).should eql nil
  end

  it 'translates a bco-dmo "wkt" point format geojson to appopriate spatial coverage values' do
    multipoint = { 'type' => 'Multipoint', 'geometry' => '<http://www.opengis.net/def/crs/OGC/1.3/CRS84> MULTIPOINT(-122.6446 48.4057, -122.7774 48.1441, -122.6621 48.413, -123.6363 48.1509, -124.7382 48.3911, -124.7246 48.3869)' }
    result = @translator.translate_geometry(multipoint)
    result[:spatial_display].size.should eql 6
    result[:spatial_index].size.should eql 6
    result[:spatial_area].should eql 0.0
    result[:global_facet].should eql nil
    result[:spatial_scope_facet].size.should eql 1
    result[:spatial_scope_facet][0].should eql 'Less than 1 degree of latitude change | Local'
  end

  it 'translates a bco-dmo "wkt" poly format to appropriate spatial coveage values' do
    box = { 'type' => 'Polygon', 'geometry' => '<http://www.opengis.net/def/crs/OGC/1.3/CRS84> POLYGON((-82.4480 57.566, -38.7980 57.566, -38.7980 24.499, -82.4480 24.499, -82.4480 57.566))' }
    result = @translator.translate_geometry(box)
    result[:spatial_display].size.should eql 1
    result[:spatial_index].size.should eql 1
    result[:spatial_area].should eql 33.06700000000001
    result[:global_facet].should eql nil
    result[:spatial_scope_facet].size.should eql 1
    result[:spatial_scope_facet][0].should eql 'Between 1 and 170 degrees of latitude change | Regional'
  end

  it 'translates a bco-dmo "wkt" linestring format to appropriate spatial coveage values' do
    box = { 'type' => 'LineString', 'geometry' => '<http://www.opengis.net/def/crs/OGC/1.3/CRS84> LINESTRING(-66.6300 44.16, -66.8117 44.4217, -66.8150 43.5067, -66.6633 44.7633, -66.8750 44.9683, -66.3750 44.54, -67.4233 44.175, -68.4817 44.2867, -68.5283 44.2083, -68.7317 44.315, -68.7167 44.1083, -68.8017 44.1267, -68.9600 44.1167, -68.9717 44.3883, -68.1867 44.1517, -66.8017 44.975, -66.3150 44.8583, -66.2233 44.595, -66.6217 44.4567, -67.1050 44.5633, -68.1250 44.0767, -68.0683 43.6183, -69.4250 43.6067, -69.9967 43.6833, -66.5250 43.3433, -66.5583 43.1267, -65.1583 43.215, -64.9217 43.5517, -64.6133 43.74, -65.5650 42.7283, -65.9483 43.2283, -67.3467 43.3, -67.1067 43.1083, -66.7700 43.0017, -65.5483 42.6683, -66.0700 42.4783, -66.3483 42.77, -66.3317 43.9883, -66.7500 44.1817, -66.5617 42.9733, -66.7433 44.7417, -67.0917 45.0483, -67.0217 45.09, -66.9350 45.0917, -66.3817 44.8933, -65.8333 44.8617, -65.9617 43.2917, -66.2650 43.2, -66.5750 42.955, -66.0967 44.4433, -66.1117 44.51, -65.9850 44.7367, -67.3417 44.22, -67.8417 43.8817, -68.3067 43.675)' }
    result = @translator.translate_geometry(box)
    result[:spatial_display].size.should eql 55
    result[:spatial_index].size.should eql 55
    result[:spatial_area].should eql 0.0
    result[:global_facet].should eql nil
    result[:spatial_scope_facet].size.should eql 1
    result[:spatial_scope_facet][0].should eql 'Less than 1 degree of latitude change | Local'
  end
end
