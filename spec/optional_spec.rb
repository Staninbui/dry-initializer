describe "optional value" do
  context "when has no default value" do
    before do
      class Test::Foo
        extend Dry::Initializer::Mixin

        param :foo
        param :bar, optional: true
      end
    end

    it "quacks like nil" do
      subject = Test::Foo.new(1)

      expect(subject.bar).to eq nil
    end

    it "keeps info about been UNDEFINED" do
      subject = Test::Foo.new(1)

      expect(subject.instance_variable_get(:@bar))
        .to eq Dry::Initializer::UNDEFINED
    end

    it "can be set explicitly" do
      subject = Test::Foo.new(1, "qux")

      expect(subject.bar).to eq "qux"
    end
  end

  context "with hide_undefined: false" do
    before do
      class Test::Foo
        extend Dry::Initializer[hide_undefined: false]

        param :foo
        param :bar, optional: true
      end
    end

    it "doesn't quack like nil" do
      subject = Test::Foo.new(1)

      expect(subject.bar).to eq Dry::Initializer::UNDEFINED
    end
  end

  context "when has a default value" do
    before do
      class Test::Foo
        extend Dry::Initializer::Mixin

        param :foo
        param :bar, optional: true, default: proc { "baz" }
      end
    end

    it "is takes default value" do
      subject = Test::Foo.new(1)

      expect(subject.bar).to eq "baz"
    end

    it "can be set explicitly" do
      subject = Test::Foo.new(1, "qux")

      expect(subject.bar).to eq "qux"
    end
  end
end
