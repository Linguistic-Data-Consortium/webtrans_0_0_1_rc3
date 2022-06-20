module DataSetsHelper
    def prepare_for_project_builder(data_set, task, randomize)
        fname = "#{task.id}_#{data_set.id}.json"
        fpath = Rails.root.join('public', 'uploads', 'data_set', 'spec', data_set.id.to_s, fname)
        make_manifest(data_set, fpath, randomize)
        # add_to_sources(fname, fpath)
        upload_manifest(data_set, fname, fpath)
        update_task(data_set, task, fname)
    end

    def update_task(data_set, task, fname)
        @task = task
        @task.meta['docid'] = fname
        @task.data_set = data_set
        @task.save!
    end

    def make_manifest(data_set, fpath, randomize)
        manifest = Manifest.new(data_set.spec.file.file, fpath)
        manifest.make_json_manifest(randomize)
    end

    # def add_to_sources(fname, fpath)
    #     Source.create!(uid: fname, path: fpath)
    # end

    def upload_manifest(data_set, fname, fpath)
        data_set.manifest.attach(io: File.open(fpath), filename: fname, content_type: 'application/json')
        File.delete(fpath)
    end
end