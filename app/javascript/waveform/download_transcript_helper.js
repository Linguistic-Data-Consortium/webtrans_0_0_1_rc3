import { create_download_tsv } from '../work/download_helper'
function create_transcript(kit_uid, include_speaker, include_section, include_headers, segs){
  let rows = [];
  let columns = [
    [ 'Kit', 'kit' ],
    [ 'Audio', 'docid' ],
    [ 'Beg', 'beg' ],
    [ 'End', 'end' ],
    [ 'Text', 'text' ]
  ];
  if(include_speaker){
    columns.push([ 'Speaker', 'speaker' ]);
  }
  if(include_section){
    columns.push([ 'Section', 'section' ]);
  }
  const docids = {};
  for(let x of segs){
    if(!x.docid) x.docid = '';
    if(!docids[x.docid]) docids[x.docid] = x.docid.replace(/.+\//, '');
    let h = {
      kit: kit_uid,
      docid: docids[x.docid],
      beg: x.beg,
      end: x.end,
      text: x.text
    };
    if(include_speaker){
      h.speaker = x.speaker;
    }
    if(include_section){
      h.section = x.section ? x.section.name : '';
    }
    rows.push(h);
  }
  return create_download_tsv(rows, columns, include_headers, 'yes', null);
}
export { create_transcript }
