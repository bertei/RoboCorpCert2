*** Settings ***
Documentation   Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.

Library    RPA.Browser.Selenium
Library    RPA.Excel.Files
Library    RPA.HTTP
Library    RPA.PDF
Library    RPA.Tables
Library    RPA.Archive
Library    RPA.Dialogs
Library    RPA.Robocorp.Vault
Library    RPA.FileSystem

*** Keywords ***
Open Browser from Vault
    ${mainUrl}=    Get Secret     website    
    Open Available Browser    ${mainUrl}[url]
    #https://robotsparebinindustries.com/#/robot-order

*** Keywords ***
Close the annoying modal
    Wait Until Page Contains Element   css:.btn-danger    
    Click Button    css:.btn-danger   

*** Keywords ***
Get CSV from user input
    Add text input    csvUrlInput    label=Insert CSV url
    ${response}=    Run dialog
    [Return]    ${response.csvUrlInput}
    #https://robotsparebinindustries.com/orders.csv

*** Keywords ***
Download CSV and Get Orders
    ${csvArchive}=   Get CSV from user input
    Download    ${csvArchive}    overwrite=True
    ${orderList}=     Read table from CSV    orders.csv   
    [Return]    ${orderList}

*** Keywords ***
Complete form from csv data
    [Arguments]    ${orders}

    ${head_as_string}=    Convert To String    ${orders}[Head]
    Select From List By Value    id:head    ${head_as_string}

    ${body_as_int}    Convert To Integer    ${orders}[Body]
    Click Element    id-body-${body_as_int}

    ${legs_as_string}=    Convert To String    ${orders}[Legs]
    Input Text    xpath://label[contains(.,'3. Legs:')]/../input    ${legs_as_string}
    
    Input Text    id:address    ${orders}[Address]

*** Keywords ***
Preview Robot
    Wait Until Page Contains Element    id:preview
    Click Button    id:preview
    Wait Until Element Is Visible    id:robot-preview-image
*** Keywords ***
Order Robot
    Wait Until Page Contains Element    id:order
    FOR    ${i}    IN RANGE   5
        Click Button    id:order
        ${order-ok}=    Does Page Contain Element    id:order-completion
        Log    ${order-ok}
        Exit For Loop If    ${order-ok}
    END
*** Keywords ***
Order Another Robot
    #Wait Until Page Contains Element    id:order-another
    Click Button    id:order-another

*** Keywords ***
Store the receipt as a PDF file
    [Arguments]    ${order_number}
    Wait Until Element Is Visible    id:order-completion
    ${receipt_html}    Get Element Attribute    id:order-completion    outerHTML
    Html To Pdf    ${receipt_html}    ${CURDIR}${/}output${/}receipts${/}${order_number}.pdf
    [Return]    ${CURDIR}${/}output${/}receipts${/}${order_number}.pdf

*** Keywords ***
Robot screenshot
    [Arguments]    ${order_number}
    Wait Until Element Is Visible    robot-preview-image
    Screenshot    robot-preview-image    ${CURDIR}${/}output${/}receipts${/}${order_number}.PNG
    [Return]    ${CURDIR}${/}output${/}receipts${/}${order_number}.PNG
*** Keywords ***
Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Open Pdf    ${pdf}
    Add Watermark Image To Pdf    ${screenshot}    ${pdf}
    Close Pdf

*** Keywords ***
Pdfs ZIP File
    Archive Folder With Zip    ${CURDIR}${/}output${/}receipts   ${CURDIR}${/}output${/}receipt.zip

*** Keywords ***
Fill each form with user's data
    ${orders}=     Download CSV and Get Orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Complete form from csv data    ${row}
        Preview Robot
        Order Robot
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Robot screenshot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Remove File    ${screenshot}
        Order Another Robot   
    END
    Pdfs ZIP File
    Close Browser
*** Tasks ***
Exec 
    Open Browser from Vault
    [TearDown]    Fill each form with user's data
    



