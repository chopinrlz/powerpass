import { PowerPassLocker } from './powerpass';

console.log('debug: loading startup.js');

declare var rivets:any, $:any;

// Load data binding
class IndexClass {
    powerpass: PowerPassLocker;
    locker!: PowerPassLocker;
    message: string;
    loaded: boolean;

    constructor() {
        
        this.powerpass = new PowerPassLocker();

        this.message = 'Welcome to the browser edition of PowerPass';
        this.loaded = false;
        rivets.bind($('body'), { data: this });
    }

    async openLocker() {
        this.message = 'Fetching your Locker';
        this.powerpass.init();
        if( this.powerpass.secrets.length <= 0 ) {
            this.powerpass.add(this.powerpass.newSecret());
        }
        this.locker = this.powerpass;
        this.loaded = true;
        this.message = 'Ready';
    }

    async closeLocker() {
        var locker = this.powerpass.encrypt('testing');
        localStorage.setItem('powerpass',locker);
        this.message = 'Welcome to the browser edition of PowerPass';
        this.loaded = false;
        (this.locker as any) = undefined;
    }

    async addSecret() {
        this.message = 'Adding Secret';
        var title = $('#textTitle').val();
        if( title ) {
            var found = this.locker.secrets.find(s => s.title === title);
            if( found ) {
                this.message = 'Secret ' + title + ' already exists'; 
            } else {
                var secret = this.powerpass.newSecret();
                secret.title = title;
                this.powerpass.add(secret);
                this.locker = this.powerpass;
                this.message = 'Locker Secrets: ' + this.powerpass.secrets.length;
                this.clearInputs();
            }
        } else {
            this.message = 'Secrets must have a unique Title';
        }
    }
    async revealPw(me:any) {
        var found = this.locker.secrets.find(s => s.title === me.id);
        if(found) this.reveal(found);
    }
    reveal(item:any) {
        item.revealed = !(item.revealed);
    }
    clearInputs() {
        $('#textTitle').val('');
        $('#textUsername').val('');
        $('#textPassword').val('');
    }
}

(window as any)["objIndex"] = new IndexClass();