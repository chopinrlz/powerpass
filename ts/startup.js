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
    async openLocker() {
        this.message = 'Fetching your Locker';
        powerpass.init();
        if( powerpass.secrets.length <= 0 ) {
            powerpass.add(powerpass.newSecret());
        }
        this.locker = powerpass;
        this.loaded = true;
        this.message = 'Ready';
    }
    async closeLocker() {
        var locker = powerpass.encrypt('testing');
        localStorage.setItem('powerpass',locker);
        this.message = 'Welcome to the browser edition of PowerPass';
        this.loaded = false;
        this.locker = undefined;
    }
    async addSecret() {
        this.message = 'Adding Secret';
        var title = $('#textTitle').val();
        if( title ) {
            var found = this.locker.secrets.find(s => s.title === title);
            if( found ) {
                this.message = 'Secret ' + title + ' already exists'; 
            } else {
                var secret = powerpass.newSecret();
                secret.title = title;
                powerpass.add(secret);
                this.locker = powerpass;
                this.message = 'Locker Secrets: ' + powerpass.secrets.length;
                this.clearInputs();
            }
        } else {
            this.message = 'Secrets must have a unique Title';
        }
    }
    async revealPw(me) {
        var found = this.locker.secrets.find(s => s.title === me.id);
        if(found) this.reveal(found);
    }
    reveal(item) {
        item.revealed = !(item.revealed);
    }
    clearInputs() {
        $('#textTitle').val('');
        $('#textUsername').val('');
        $('#textPassword').val('');
    }
}
let objIndex = new IndexClass();