# 作業
```
1.測試案例:(api.practicesoftwaretesting.com).xlsx
```
```
2.Postman:API - Products & Messages - Bruce.postman_collection.json
```
```自動化測試
3.執行 python3 -m robot -i tag api_test.robot
Report -> log 有截圖(robot可透過每次執行完畢後自動產生log+report)
```
```
4.效能測試 測試計劃書+jmx檔+截圖
```


# Installation (Mac) 
Robot Framework 是一個基於 python 的 自動化框架，基本上可以用 python 達成的事情，Robot Framework 都可以做到，其應用的場景是 ATDD (Acceptance Test Driven Development)、BDD (Behavior Driven Development) 以及可以被機器化的流程。
## 0.Homebrew

```bash
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)”
```

## 1.Install robot framework

````
You could exe. the command line below
```bash
pip3 install -r requirements.txt
````

## 2. Install Selenium

```bash
pip3 install selenium
```

## 3. Download chrome driver

https://googlechromelabs.github.io/chrome-for-testing/

Put chromedriver under usr/local/bin (mac)

# Robot Execution

Some of Ref : https://robotframework.org/SeleniumLibrary/

## 1. Execute Robot Code

To execute the entire Robot Framework test suite on macOS, use the following command:

```bash
python3 -m robot api_test.robot
```

## 2. Execute robot code with specific tag

To run tests that match a specific tag, use the -i (or --include) option:

For Mac

```bash
python3 -m robot -i tag api_test.robot
```

Example:

To run only the tests tagged with one tag, use:

```bash
python3 -m robot -i case1 api_test.robot
```
# Cathay-United-Bank_Assignment
