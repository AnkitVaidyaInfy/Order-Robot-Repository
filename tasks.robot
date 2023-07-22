*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library    RPA.Browser.Selenium    auto_close=${FALSE}
Library    RPA.HTTP
Library    RPA.Tables
Library    RPA.PDF
Library    RPA.RobotLogListener
Library    BuiltIn
Library    OperatingSystem
Library    RPA.Archive

*** Variables ***
${output_folder}    ${OUTPUT_DIR}${/}Output
${img_folder}     ${output_folder}${/}image
${pdf_folder}     ${output_folder}${/}pdf
${zip_file}       ${output_folder}${/}pdf_archive.zip

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Directory Cleanup
    Open the robot order website
    Download the CSV file
    Read CSV file and fill the orders details
    Create a ZIP file of receipt PDF files
    Log Out And Close The Browser

*** Keywords ***
Directory Cleanup
    Create Directory    ${output_folder}
    Empty Directory    ${output_folder}
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order
    Maximize Browser Window

Download the CSV file
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True

Read CSV file and fill the orders details
    ${table}=    Read table from CSV    orders.csv
    FOR    ${order}    IN    @{table}
        Close the annoying modal
        Fill and submit the form for one order    ${order}
        Preview the robot
        Submit the order
        Store the receipt as a PDF file    ${order}[Order number]
        Order another order
    END

Close the annoying modal
    Wait Until Page Contains Element    xpath://*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]
    Wait Until Keyword Succeeds    1 min    0.5 sec    Click Button    xpath://*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]

Fill and submit the form for one order
    [Arguments]    ${order}
    Select From List By Value    xpath://*[@id="head"]    ${order}[Head]
    #Click Button    id-body-${order}[Body]
    Select Radio Button    body    ${order}[Body]
    Input Text    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${order}[Legs]
    Input Text    address    ${order}[Address]

Preview the robot
    # Define local variables for the UI elements
    Set Local Variable              ${btn_preview}      //*[@id="preview"]
    Set Local Variable              ${img_preview}      //*[@id="robot-preview-image"]
    Wait Until Keyword Succeeds    1 min    0.5 sec    Click Button    ${btn_preview}
    Wait Until Element Is Visible   ${img_preview}

Submit the order
    # Define local variables for the UI elements
    Wait Until Keyword Succeeds    1 min    0.5 sec    Click Button    xpath=/html/body/div/div/div[1]/div/div[1]/form/button[2]
    ${Error_Accured}=    Run Keyword And Return Status    Page Should Contain Element    order-another
    IF    ${Error_Accured} == False
        Sleep    2sec
        Submit the order
    END

Store the receipt as a PDF file
    [Arguments]    ${Order number}
    ${receipt_html}=    Get Element Attribute    xpath=//*[@id="receipt"]    outerHTML
    Html To Pdf    ${receipt_html}    ${pdf_folder}${/}receipt_${Order number}.pdf
    Embed the robot screenshot to the receipt PDF File    ${pdf_folder}${/}receipt_${Order number}.pdf    ${Order number}

Embed the robot screenshot to the receipt PDF File
    [Arguments]    ${pdf}    ${Order number}
    Sleep    2sec
    Capture Element Screenshot    robot-preview-image    ${img_folder}${/}robot_${Order number}.png
    Open Pdf    ${pdf}
    ${list}=    Create List
    ...    ${img_folder}${/}robot_${Order number}.png
    Add Files To Pdf    ${list}    ${pdf}    append=${True}
    Close Pdf    ${pdf}

Order another order
    Wait Until Keyword Succeeds    1 min    0.5 sec    Click Button    order-another

Create a ZIP file of receipt PDF files
    Archive Folder With ZIP     ${pdf_folder}  ${zip_file}   recursive=True  include=*.pdf

Log Out And Close The Browser
    Close Browser