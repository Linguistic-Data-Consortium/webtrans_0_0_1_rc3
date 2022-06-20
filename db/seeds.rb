# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

NodeValue.where(id: 0).first_or_create
ncs = ["Leaf","Root","Node","List","Text","Label","Date","Gaz","children","Button","Checkbox","EmbeddedList","Tabs","TextSource","TextSearch","MultiMenu","CustomText","Audio","Coref","CorpusSearch","Table","EntryLabel","ToggleButton","Audio2","Message","TextSource2","ChoiceLabel","Wave","Upload","Download","ButtonGroupRadio","Blob","Media","Image"]
ncs.each {|x| NodeClass.where(name: x).first_or_create}
PreferenceType.where(name: "Show Admin Buttons", values: "show, hide").first_or_create
Workflow.where(name: 'OnTheFly', user_states: 'needs_kit,has_kit').first_or_create
Workflow.where(name: 'Orderly', user_states: 'needs_kit,has_kit').first_or_create
