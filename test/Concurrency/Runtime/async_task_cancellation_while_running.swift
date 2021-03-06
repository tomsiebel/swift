// RUN: %target-run-simple-swift(-Xfrontend -enable-experimental-concurrency  %import-libdispatch -parse-as-library)

// REQUIRES: executable_test
// REQUIRES: concurrency
// REQUIRES: libdispatch

import Dispatch

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

func test_runDetached_cancel_while_child_running() async {
  let h: Task.Handle<Bool, Error> = Task.runDetached {
    async let childCancelled: Bool = { () -> Bool in
      sleep(3)
      return Task.isCancelled
    }()

    let childWasCancelled = await childCancelled
    print("child, cancelled: \(childWasCancelled)") // CHECK: child, cancelled: true
    let selfWasCancelled =  Task.isCancelled
    print("self, cancelled: \(selfWasCancelled )") // CHECK: self, cancelled: true
    return selfWasCancelled
  }

  // sleep here, i.e. give the task a moment to start running
  sleep(2)

  h.cancel()
  print("handle cancel")
  let got = try! await h.get()
  print("was cancelled: \(got)") // CHECK: was cancelled: true
}

@main struct Main {
  static func main() async {
    await test_runDetached_cancel_while_child_running()
  }
}
