
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_suite_number, ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address,
        ca_street_type,
        LOWER(ca_country) AS country_lowercase
    FROM 
        customer_address
), CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_credit_rating
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), ReturnStatistics AS (
    SELECT 
        sr_customer_sk,
        COUNT(sr_item_sk) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
), FinalReport AS (
    SELECT 
        c.c_customer_sk AS Customer_SK,
        c.full_name AS Customer_Name,
        a.full_address AS Address,
        a.ca_street_type AS Street_Type,
        c.cd_gender AS Gender,
        c.cd_marital_status AS Marital_Status,
        r.total_returns AS Returns_Count,
        r.total_return_amount AS Returns_Total_Amount,
        a.country_lowercase AS Country
    FROM 
        CustomerDetails c
    LEFT JOIN 
        AddressDetails a ON c.c_customer_sk = a.ca_address_sk
    LEFT JOIN 
        ReturnStatistics r ON c.c_customer_sk = r.sr_customer_sk
    WHERE 
        a.country_lowercase IN ('usa', 'canada')
        AND r.total_return_amount > 100
)
SELECT 
    Customer_SK,
    Customer_Name,
    Address,
    Street_Type,
    Gender,
    Marital_Status,
    Returns_Count,
    Returns_Total_Amount
FROM 
    FinalReport
ORDER BY 
    Returns_Total_Amount DESC;
