import { PowerPassLocker } from './powerpass';
import { Secret } from './powerpass';

console.log('debug: loading startup.js');

// Forward declarations for Rivets and jQuery objects
declare var rivets:any, $:any;

// The controller for index.html
class IndexClass {
    powerpass: PowerPassLocker;
    locker!: PowerPassLocker;
    message: string;
    loaded: boolean;

    /**
     * Creates the IndexClass instance which implements the front-end for PowerPass
     */
    constructor() {
        this.powerpass = new PowerPassLocker();
        this.message = 'Welcome to the browser edition of PowerPass';
        this.loaded = false;
        rivets.bind($('body'), { data: this });
    }

    /**
     * Opens your PowerPass Locker from local storage if it is not already open
     */
    async openLocker() {
        if( !(this.loaded) ) {
            this.message = 'Fetching your Locker';
            this.powerpass.init();
            if( this.powerpass.secrets.length <= 0 ) {
                this.powerpass.add(this.powerpass.newSecret());
            }
            this.locker = this.powerpass;
            this.loaded = true;
            this.message = 'Ready';
        } else {
            this.message = 'Your Locker is already open';
        }
    }

    /**
     * Closes your PowerPass Locker saving it to local storage if it is currently open
     */
    async closeLocker() {
        if( this.loaded ) {
            var locker = this.powerpass.encrypt('testing');
            localStorage.setItem('powerpass',locker);
            this.message = 'Welcome to the browser edition of PowerPass';
            this.loaded = false;
            (this.locker as any) = undefined;
        } else {
            this.message = 'Your Locker is not open';
        }
    }

    /**
     * Adds a new Locker secret from the Title, Username, and Password inputs
     */
    async addSecret() {
        this.message = 'Adding Secret';
        var title = $('#textTitle').val();
        if( title ) {
            if( (typeof this.locker) !== undefined ) {
                var found = this.locker.secrets.find(s => s.title === title);
                if( found ) {
                    this.message = 'Secret ' + title + ' already exists'; 
                } else {
                    var secret = this.powerpass.newSecret();
                    secret.title = title;
                    var username = $('#textUsername').val();
                    if( username ) secret.username = username;
                    var password = $('#textPassword').val();
                    if( password ) secret.password = password;
                    this.powerpass.add(secret);
                    this.locker = this.powerpass;
                    this.message = 'Locker Secrets: ' + this.powerpass.secrets.length;
                    this.clearInputs();
                }
            } else {
                this.message = 'Locker is not open';
            }
        } else {
            this.message = 'Secrets must have a unique Title';
        }
    }

    /**
     * Reveals a password on the main page
     * @param me The clicked Button element with rv-id set to the Title of the secret
     */
    async revealPw(me: any) {
        if( (typeof this.locker) !== undefined ) {
            var found: Secret | undefined = this.locker.secrets.find(s => s.title === me.id);
            if(found) this.reveal(found);
        }
    }

    /**
     * Inverts the revealed flag on a PowerPass Locker secret
     * @param item The Secret's password to reveal or hide
     */
    reveal(item: Secret) {
        item.revealed = !(item.revealed);
    }

    /**
     * Erases all the text entered into the Title, Username, and Password boxes
     */
    clearInputs() {
        $('#textTitle').val('');
        $('#textUsername').val('');
        $('#textPassword').val('');
    }
}

// Create objIndex for the page
(window as any)["objIndex"] = new IndexClass();