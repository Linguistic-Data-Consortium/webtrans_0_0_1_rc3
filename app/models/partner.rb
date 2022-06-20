class Partner < ApplicationRecord
    validates :name, :presence => true
    belongs_to :project
    has_one_attached :image

    def full_url
        if !url.start_with?("http")
            "http://" + url
        else
            url
        end
    end
end
