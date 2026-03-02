<a id="readme-top"></a>

<br />
<div align="center">
  <a href="https://github.com/galaximaster/wordini">
    <img src="assets/icons/Wordini_app_icon.png" alt="Logo" width="80" height="80">
  </a>

  <h3 align="center">Wordini</h3>

  <p align="center">
    An AI-powered vocabulary builder integrated into English language curriculums.
    <br />
    <a href="https://github.com/galaximaster/wordini"><strong>Explore the docs »</strong></a>
    <br />
    <br />
    <a href="https://play.google.com/store/apps/details?id=com.smartspace.wordini">Google Play</a>
    &middot;
    <a href="https://apps.apple.com/au/app/wordini/id6747973066">Apple Store</a>
  </p>
  </p>
</div>

<details>
  <summary>Table of Contents</summary>
  <ol>
    <li>
      <a href="#about-the-project">About The Project</a>
      <ul>
        <li><a href="#built-with">Built With</a></li>
      </ul>
    </li>
    <li>
      <a href="#getting-started">Getting Started</a>
      <ul>
        <li><a href="#prerequisites">Prerequisites</a></li>
        <li><a href="#installation">Installation</a></li>
      </ul>
    </li>
    <li><a href="#usage">Usage</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
  </ol>
</details>

## About The Project

<!-- [![Wordini Screen Shot][product-screenshot]](https://example.com) -->

Wordini was developed to solve a specific gap in vocabulary retention for students at Smart Space Tutoring. While most flashcard apps are generic, Wordini uses AI to provide contextual definition recognition, ensuring students aren't just memorizing words, but understanding their usage.

**Key Features:**

* **AI Definition Checker:** Integrated OpenAI API to verify student definitions in real-time.
* **Progress Tracking:** Interactive statistics for "Words Added" and "Word Testing" goals.
* **Responsive UI:** Built with a "mobile-first" approach for both iOS and Android.
* **State Management:** Utilizes Riverpod for reactive, scalable data flow.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

### Built With

* [![Flutter][Flutter.dev]][Flutter-url]
* [![Dart][Dart.dev]][Dart-url]
* [![Riverpod][Riverpod.dev]][Riverpod-url]
* [![Firebase][Firebase.google.com]][Firebase-url]
* [![OpenAI][OpenAI.com]][OpenAI-url]
* [![Cloudflare][Cloudflare]][Cloudflare-url]

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Getting Started

### Prerequisites

* [Flutter SDK](https://docs.flutter.dev/install)

```bash
flutter doctor
```

### Installation

1. **Clone the repo**

```bash
git clone https://github.com/galaximaster/wordini
```

2. **Install Flutter packages**

```bash
flutter pub get
```

3. **Firebase Setup**

   * Create a Firebase project at [Firebase Console](https://console.firebase.google.com/).
   * Add an Android/iOS app to the project and download the `google-services.json` or `GoogleService-Info.plist`.
   * Place the files in `android/app/` and `ios/Runner/` respectively.

4. **Environment Variables**

   * Create a `.env` file in the root directory.
   * Add your Keys:

```env
MERRIAM_WEB_API_KEY=
ENCRYPTION_KEY=
serverClientId=
clientIdGcloud=
gptApiWorkerLink=
```
  * run `dart run build_runner build` to build the /env/env.g.dart

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Usage

Wordini is designed to be a high-frequency tool for students. The core workflow involves:

1. **Word Acquisition:** Students add new words from their tutoring sessions or external readings.
2. **AI Verification:** OpenAI integration verifies the student's definition to ensure correct context.
3. **Retention Quizzing:** A dynamic quiz algorithm prioritises newer and weaker words.

### Architectural Decisions

* **State Management:** Riverpod was chosen over Bloc for compile-time safety and easy testing of the OpenAI service.
* **Local Persistence:** Hive is used for the local storage to easily store json format.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- ## Roadmap

<!-- <p align="right">(<a href="#readme-top">back to top</a>)</p> -->

## License

Distributed under the **MIT License**. See `LICENSE` for more information.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Contact

**Dylan J** - [dmj08bot@gmail.com](mailto:dmj08bot@gmail.com)
Project Link: [Wordini GitHub](https://github.com/galaximaster/wordini)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

[Flutter.dev]: https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white
[Flutter-url]: https://flutter.dev
[Dart.dev]: https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white
[Dart-url]: https://dart.dev
[OpenAI.com]: https://img.shields.io/badge/OpenAI-412991?style=for-the-badge&logo=openai&logoColor=white
[OpenAI-url]: https://openai.com
[Firebase.google.com]: https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black
[Firebase-url]: https://firebase.google.com
[Riverpod.dev]: https://img.shields.io/badge/Riverpod-02569B?style=for-the-badge&logo=flutter&logoColor=white
[Riverpod-url]: https://riverpod.dev
[Riverpod]: https://img.shields.io/badge/Riverpod-02569B?style=for-the-badge&logo=flutter&logoColor=white
[Riverpod-url]: https://riverpod.dev
[Cloudflare]: https://img.shields.io/badge/Cloudflare-F38020?style=for-the-badge&logo=Cloudflare&logoColor=white
[Cloudflare-url]: https://www.cloudflare.com/