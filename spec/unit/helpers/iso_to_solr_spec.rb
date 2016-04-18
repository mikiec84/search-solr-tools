require 'spec_helper'

describe SearchSolrTools::Helpers::IsoToSolr do
  describe '#strip_invalid_utf8_bytes' do
    def strip_invalid_utf8_bytes(text)
      described_class.new(nil).send(:strip_invalid_utf8_bytes, text)
    end

    it 'does not mess with floats' do
      expect(strip_invalid_utf8_bytes(2.0)).to eql 2.0
    end

    it 'does not modify plain characters' do
      expect(strip_invalid_utf8_bytes('hello, world')).to eql 'hello, world'
    end

    it 'does not modify accented e characters' do
      expect(strip_invalid_utf8_bytes("\u00E9")).to eql "\u00E9"
    end

    it 'removes inverted question marks' do
      expect(strip_invalid_utf8_bytes("\u00BF")).to eql ''
    end

    it 'removes invalid UTF-8 characters' do
      expect(strip_invalid_utf8_bytes("\xFF")).to eql ''
    end
  end
end
