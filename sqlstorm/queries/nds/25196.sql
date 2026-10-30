
WITH ProcessedAddresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS Full_Address,
        LOWER(ca_city) AS Lower_City,
        UPPER(ca_state) AS Upper_State,
        CONCAT(LEFT(ca_zip, 5), '-', RIGHT(ca_zip, 4)) AS Formatted_Zip
    FROM 
        customer_address
), 
Demographics AS (
    SELECT 
        cd_demo_sk,
        CASE 
            WHEN cd_gender = 'M' THEN 'Male'
            WHEN cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS Gender,
        cd_marital_status AS Marital_Status,
        TRIM(cd_education_status) AS Education_Status
    FROM 
        customer_demographics
),
DetailedInfo AS (
    SELECT 
        a.Full_Address,
        a.Lower_City,
        a.Upper_State,
        a.Formatted_Zip,
        d.Gender,
        d.Marital_Status,
        d.Education_Status
    FROM 
        ProcessedAddresses a
    JOIN 
        Demographics d ON a.ca_address_sk = d.cd_demo_sk
)
SELECT 
    Full_Address,
    Lower_City,
    Upper_State,
    Formatted_Zip,
    COUNT(*) AS Customer_Count,
    AVG(CASE 
            WHEN Education_Status LIKE '%college%' THEN 1 
            ELSE 0 
        END) * 100 AS College_Attendance_Rate
FROM 
    DetailedInfo
GROUP BY 
    Full_Address, Lower_City, Upper_State, Formatted_Zip
ORDER BY 
    Customer_Count DESC, College_Attendance_Rate DESC
LIMIT 50;
