console.log('debug: loading startup.js');

// Load PowerPass
addScriptAtHeader('powerpass.js');

// Load data binding
class IndexClass {
    constructor() {
        this.message = 'Welcome to the browser edition of PowerPass';
        this.loaded = false;
        this.locker = undefined;
        rivets.bind($('body'), { data: this });
    }
    async btnClick() {
        this.message = 'Fetching your Locker';
        powerpass.add(powerpass.newSecret());
        this.locker = powerpass;
        this.loaded = true;
        this.message = 'Ready';
    }
    async addSecret() {
        this.message = 'Adding Secret';
        powerpass.add(powerpass.newSecret());
        this.locker = powerpass;
        this.message = 'Locker Secrets: ' + powerpass.secrets.length;
    }
}
let objIndex = new IndexClass();