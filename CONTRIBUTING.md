# Contributing

Bug reports and focused pull requests are welcome.

Before opening a pull request, run:

```sh
swift run -Xswiftc -warnings-as-errors RecognizerChecks
swift build -c release -Xswiftc -warnings-as-errors
```

Changes to gesture recognition should include a deterministic scenario in `RecognizerChecks`.
Please do not commit generated build output from `.build`, `outputs`, or `work`.
