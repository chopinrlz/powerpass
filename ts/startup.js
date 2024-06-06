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
        this.loaded = true;
        this.locker = myLocker;
        this.message = 'Ready';
    }
}
let objIndex = new IndexClass();