# garbage_scan
A flutter application designed to provide garbage recycling guidance for everyone. Built with flutter and Firebase (firestore and firebase ai extension).

You scan the barcode of your garbage, and we (either our database or Google Bard) will tell you how to recycle it.

This project was created in SunHacks 2023 within 24 hours by [@t41372](https://github.com/t41372), [@laowang0991](https://github.com/laowang0991), and [@czkcool](https://github.com/czkcool). More information on our [Devpost page](https://devpost.com/software/garbage_scan). This project won the Best Hack for Social Good and Best Sustainability award in SunHacks 2023

This application is targeted at Android, but thanks to the help from the judges and volunteers at SunHacks 2023, this app should also work on IOS. Some packages may break on the web version.

<img width="200" alt="demo1" src="https://github.com/t41372/garbage-scan/assets/36402030/f26b4cd7-e05c-4675-9bd9-2ec3c51e6804">
<img width="200" alt="demo2" src="https://github.com/t41372/garbage-scan/assets/36402030/8b3e374e-5442-4462-b479-85de4a7d74f8">
<img width="200" alt="demo3" src="https://github.com/t41372/garbage-scan/assets/36402030/4d8f9e46-c0c8-4ac5-8529-bd25a3ac8c00">


## Demonstration Video
[![Garbage Scan Demonstration](https://img.youtube.com/vi/SaOiH9RFZac/0.jpg)](https://www.youtube.com/watch?v=SaOiH9RFZac)



## Get the app
You can get the Android installation pack from [release](https://github.com/t41372/garbage-scan/releases/tag/0.1.0), but because of the barcode API we use, we expect the current version to stop working within 7 days (Nov 13, 2023). We are likely to switch the API within this week, and there will be an update for that.

Thanks to the help from Judges and Volunteers at SunHacks 2023, our flutter app can now be compiled properly to the IOS platform. But as someone who doesn't have an IOS device or an iOS developer, I need to figure out a way to distribute the package. Hence, you might have to compile the project on your computer to run this project on your iOS devices.

## Compile the app
Please clone or download the project source code to your computer, and make sure to have the Flutter development environment set up (android and ios).

Also, please change the API key in `lib/main.dart`. Get a barcode interpretation API key from https://go-upc.com and paste it into the `barcode_api_key` in `lib/main.dart`.






