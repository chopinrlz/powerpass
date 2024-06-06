console.log('debug: loading startup.js');

// Load PowerPass
addScriptAtHeader('powerpass.js');

// Load data binding
class IndexClass {
    constructor() {
        this.message = 'startup';
        rivets.bind($('body'), { data: this });
    }
    async btnClick() {
        this.message = 'Please Wait...'
        var url = 'https://www.neilb.net/wordjumblebackend/api/word/generategame';
        var data = await $.get(url);
        console.log(data);
        this.message = 'Number of rounds: ' + data.rounds.length;
    }
}
let objIndex = new IndexClass();