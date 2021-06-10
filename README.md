N.B.: Il programma al momento non può ancora sottoscriversi ai domini, è una semplice simulazione.
In ognuno dei file linkati sono presenti commenti che ne spiegano il funzionamento.

**DESCRIZIONE DEI MODULI**
           

Attraverso [gestore](https://github.com/Malvi17/ErlDomainSub/blob/main/src/gestore.erl) inizializzo l'[eventHandler](https://github.com/Malvi17/ErlDomainSub/blob/main/src/eventHandler.erl) che a sua volta con init inizializza più [subscriber](https://github.com/Malvi17/ErlDomainSub/blob/main/src/subscriber.erl).<br/> 
Ognuno di questi processi viene definito come un handler della libreria di [Erlbus](https://github.com/cabol/erlbus) attraverso la funzione **crea**.

[Erlbus](https://github.com/cabol/erlbus) è una libreria che ho utilizzato per definire un **publisher** e più **subscribers** dato che su Erlang è possibile solo mandare un messaggio alla volta senza possibilità di fare broadcasting. <br/>
Di questa libreria ho utilizzato 3 funzioni:
* **H = ebus_proc:spawn_handler(fun provaSub:handle_msg/2,[self()])** Crea un processo che chiamerà l callback **handleMsg** appena riceverà un messaggio dal topic in cui si sottoscritto
* **ebus:sub(H,domain)** Sottoscrive l'hanler H al topic di nome **domain**
* **ebus:pub(domain,"parti")** Invia a tutti i sottoscrittori del topic **domain** il messaggio "parti".(Qualsiasi sia il messaggio l'handler parte comunque, in questo caso non ho necessita di filtrare i messaggi).

Il modulo [subscriber](https://github.com/Malvi17/ErlDomainSub/blob/main/src/subscriber.erl) fornisce semplicemente un processo che attraverso **handle_msg** stampa a video il proprio Pid il messaggio ricevuto e il Pid dell'eventHandler che lo ha generato.

Il modulo [eventHandler](https://github.com/Malvi17/ErlDomainSub/blob/main/src/eventHandler.erl) è un modulo con behaviour **gen_event** che rimane in attesa del [domainStatusLookup](https://github.com/Malvi17/ErlDomainSub/blob/main/src/domainStatusLookup.erl).<br/>
Questo modulo insieme a [dominio](https://github.com/Malvi17/ErlDomainSub/blob/main/src/dominio.erl) è la parte più simulativa del progetto.<br/> 
Per ora [dominio](https://github.com/Malvi17/ErlDomainSub/blob/main/src/dominio.erl) corrisponde semplicemente alla creazione di un socket che rimane in attesa della connessione da parte di [domainStatusLookup](https://github.com/Malvi17/ErlDomainSub/blob/main/src/domainStatusLookup.erl).<br/> 
Infine passati 10 secondi invia un messaggio che appena ricevuto genera l'invio dello stato **libero** da parte del [domainStatusLookup](https://github.com/Malvi17/ErlDomainSub/blob/main/src/domainStatusLookup.erl) al [eventHandler](https://github.com/Malvi17/ErlDomainSub/blob/main/src/eventHandler.erl).<br/> 
Questo invio utilizza la funzione **gen_event:sync_notify** e viene cronometrata attraverso **timer:cp**.<br/> 
Viene utilizzata la versione sincrona della **notify** in modo che il risultato della **timer:cp** corrisponda alla fine della gestione da parte del Handler, se avessi usato la versione asincrona il timer si stopperebbe non appena l'evento è stato inviato.


**ESEMPIO FUNZIONAMENTO**

**Primo terminale**
2> {ok,Pid} = gestore:start_link().

Processo <0.162.0> creato e subbato al topic domain<br/>
Processo <0.163.0> creato e subbato al topic domain<br/>
Processo <0.164.0> creato e subbato al topic domain<br/>
Processo <0.165.0> creato e subbato al topic domain<br/>
Tutti i processi sono stati creati<br/>
{ok,<0.161.0>}<br/>

3> domainStatusLookup:start(Pid).

Ci ha messo 0.18400 ms<br/>
ok<br/>
[Pid: <0.162.0>][Msg: "parti"][Ctx: <0.161.0>]<br/>
[Pid: <0.163.0>][Msg: "parti"][Ctx: <0.161.0>]<br/>
[Pid: <0.164.0>][Msg: "parti"][Ctx: <0.161.0>]<br/>
[Pid: <0.165.0>][Msg: "parti"][Ctx: <0.161.0>]<br/>

**Secondo terminale**

2> dominio:server().<br/>
ok
