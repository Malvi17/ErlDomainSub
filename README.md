N.B.: Il programma al momento non può ancora sottoscriversi ai domini, è una semplice simulazione.
In ognuno dei file linkati sono presenti commenti che ne spiegano il funzionamento.

ESEMPIO DI FUNZIONAMENTO

**2> {ok,Pid} = gestore:start_link()**.             

Prima ed unica funzione del modulo [gestore](https://github.com/Malvi17/ErlDomainSub/blob/main/src/gestore.erl).

Attraverso gestore quindi inizializzo l'[eventHandler](https://github.com/Malvi17/ErlDomainSub/blob/main/src/eventHandler.erl) che a sua volta con init inizializza più [subscriber](https://github.com/Malvi17/ErlDomainSub/blob/main/src/subscriber.erl). Ognuno di questi processo viene definito come un handler della libreria di [Erlbus](https://github.com/cabol/erlbus) attraverso la funzione **crea**.

[Erlbus](https://github.com/cabol/erlbus) è una libreria che ho utilizzato per definire un **publisher** e più **subscribers** dato che su Erlang è possibile solo mandare un messaggio alla volta senza possibilità di fare broadcasting. Di questa libreria ho utilizzato 3 funzioni:
* **H = ebus_proc:spawn_handler(fun provaSub:handleMsg/2,[self()])** Crea un processo che chiamerà l callback **handleMsg** appena riceverà un messaggio dal topic in cui si sottoscritto
* **ebus:sub(H,domain)** Sottoscrive l'hanler H al topic di nome **domain**
* **ebus:pub(domain,"parti")** Invia a tutti i sottoscrittori del topic **domain** il messaggio "parti".(Qualsiasi sia il messaggio l'handler parte comunque, in questo caso non ho necessita di filtrare i messaggi).


Il modulo [subscriber](https://github.com/Malvi17/ErlDomainSub/blob/main/src/subscriber.erl) fornisce semplicemente un processo 





