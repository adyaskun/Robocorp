*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${False}
Library             RPA.HTTP
Library             RPA.Excel.Files
Library             RPA.Tables
Library             Telnet
Library             RPA.Dialogs
Library             RPA.PDF
Library             RPA.Robocloud.Secrets


*** Tasks ***
Order Robot
    #Test WorkFlow
    Open the robot order website
    Download the order file
    #Close unwanted popup
    Read order form
    #Success Dialogs
    #Fill form details


*** Keywords ***
Open the robot order website
    #Get the data from vault
    ${secret}=    Get Secret    WebDetails
    #Open Available Browser    https://robotsparebinindustries.com/#/robot-order    maximized=True
    Open Available Browser    ${secret}[URL]    maximized=True
    Wait Until Page Contains    OK

Test WorkFlow
    ${OrderNumber}=    Get Element Attribute    css:badge-success    outerHTML

Success Dialogs
    Add icon    Success
    Add heading    Order addedd
    Run dialog    title= Success

Input from user dialog
    Add heading    Enter file download url
    Add text input    URL    placeholder=Enter your URL    label=URL for download file
    ${Result}=    Run dialog
    RETURN    ${Result.URL}

Close unwanted popup
    #Click Button    css:button.btn-dark
    Click Element    css:button.btn-dark

Download the order file
    ${URL}=    Input from user dialog
    #Download    https://robotsparebinindustries.com/orders.csv    overwrite=${True}
    Download    ${URL}    overwrite=${True}

Fill form details
    [Arguments]    ${OrderData}
    Close unwanted popup
    Select From List By Value    head    ${OrderData}[Head]
    Select Radio Button    body    ${OrderData}[Body]
    Input Text    xpath:.//input[@placeholder='Enter the part number for the legs']    ${OrderData}[Legs]
    Input Text    address    ${OrderData}[Address]
    Click Button    preview
    Take screenshot of robot    ${OrderData}[Order number]
    Click Button    order
    Wait Until Page Contains Element    receipt
    ${OrderNumber}=    Get Text    css:p.badge-success
    Store the order receipt as a PDF file    ${OrderData}[Order number]
    Embeds screenshot to PDF    ${OrderData}[Order number]

Take screenshot of robot
    [Arguments]    ${OrderNumber}
    Screenshot    robot-preview-image    ${OUTPUT_DIR}${/}Receipts/ScreenShot_${OrderNumber}.PNG

Store the order receipt as a PDF file
    [Arguments]    ${OrderNumber}
    ${ReceiptData}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${ReceiptData}    ${OUTPUT_DIR}${/}Receipts/Receipt_${OrderNumber}.pdf

Embeds screenshot to PDF
    [Arguments]    ${OrderNumber}
    ${ReceiptPDF}=    Open Pdf    ${OUTPUT_DIR}${/}Receipts/Receipt_${OrderNumber}.pdf
    ${RobotPDFData}=    Create List
    ...    ${OUTPUT_DIR}${/}Receipts/ScreenShot_${OrderNumber}.PNG
    ...    ${OUTPUT_DIR}${/}Receipts/Receipt_${OrderNumber}.pdf
    Add Files To Pdf    ${RobotPDFData}    ${OUTPUT_DIR}${/}Receipts/Receipt_${OrderNumber}.pdf
    Close Pdf    ${ReceiptPDF}

Read order form
    ${OrderData}=    Read table from CSV    orders.csv    header=True
    FOR    ${row}    IN    @{OrderData}
        Wait Until Keyword Succeeds    3x    2s    Fill form details    ${row}
        #Log    ${row}
        Success Dialogs
        Click Button    order-another
        Wait Until Page Contains    OK
    END
