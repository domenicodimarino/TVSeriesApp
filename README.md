# DOMFlix 📺

DOMFlix è un'app Flutter per la gestione delle serie TV che permette di:

- Aggiungere, modificare e rimuovere serie TV dal proprio database personale.
- Gestire stagioni ed episodi per ogni serie, segnando quelli già visti.
- Visualizzare statistiche e analisi sulle serie guardate, in corso e da guardare.
- Cercare e filtrare le serie per titolo, genere, piattaforma o stato.
- Contrassegnare le serie preferite.
- Salvare immagini delle serie sia da URL che dalla galleria locale.
- Ricevere suggerimenti intelligenti basati sui propri gusti e preferenze.

---

## 📁 Struttura del progetto

- **lib/**: codice principale dell'app (schermate, modelli, database, widget personalizzati)
- **assets/**: immagini e risorse grafiche dell'app
- **android/**, **ios/**, **linux/**, **macos/**, **windows/**, **web/**: cartelle di piattaforma per il supporto multipiattaforma Flutter

---

## 🚀 Come iniziare

1. **Clona il repository**
   ```sh
   git clone https://github.com/domenicodimarino/TVSeriesApp.git
   cd TVSeriesApp
   ```

2. **Installa le dipendenze**
   ```sh
   flutter pub get
   ```

3. **Avvia l'app**
   ```sh
   flutter run
   ```

---

## 📱 Funzionalità principali

- 🏠 **Home**: panoramica delle serie, preferiti, in corso, da guardare e completate.
- 🍿 **Aggiunta/Modifica Serie**: inserimento dettagli, immagine, piattaforma, stato, gestione stagioni/episodi.
- 🔎 **Ricerca**: ricerca avanzata e filtri per stato, piattaforma, genere.
- 📊 **Statistiche**: grafici e dati su generi, piattaforme, progressi e serie più seguite.
- 🌇 **Gestione immagini**: supporto immagini locali e remote.

---

## 📦 Dipendenze principali

- [`sqflite`](https://pub.dev/packages/sqflite) per la gestione del database locale
- [`path_provider`](https://pub.dev/packages/path_provider) per il salvataggio delle immagini locali
- [`image_picker`](https://pub.dev/packages/image_picker) per la selezione delle immagini dalla galleria
- [`fl_chart`](https://pub.dev/packages/fl_chart) per la visualizzazione dei grafici nelle statistiche

---

## 👨‍💻 Componenti

| Nome                     | Matricola      | Email                                      |
|--------------------------|---------------|---------------------------------------------|
| Adinolfi Giovanni        | 0612708352    | g.adinolfi39@studenti.unisa.it              |
| Di Crescenzo Francesco   | 0612708640    | f.dicrescenzo2@studenti.unisa.it            |
| Di Marino Domenico       | 0612707421    | d.dimarino8@studenti.unisa.it               |
| Scandone Alessandro      | 0612707955    | a.scandone@studenti.unisa.it                |

---

> Progetto universitario per il corso di Mobile Programming, Università degli Studi di Salerno.