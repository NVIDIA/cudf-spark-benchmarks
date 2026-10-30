
WITH AddressComponents AS (
    SELECT 
        ca_address_sk,
        ca_street_number,
        ca_street_name,
        ca_street_type,
        ca_city,
        ca_state,
        ca_zip,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address
    FROM 
        customer_address
),
DemographicsWithLanguages AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        case 
            when cd_gender = 'M' then 'English, Spanish'
            when cd_gender = 'F' then 'English, French'
            else 'English'
        end AS primary_language
    FROM 
        customer_demographics
),
SalesInfo AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
FinalOutput AS (
    SELECT 
        a.ca_address_sk,
        a.full_address,
        d.cd_gender,
        d.primary_language,
        s.total_sales
    FROM 
        AddressComponents a
    JOIN 
        customer c ON a.ca_address_sk = c.c_current_addr_sk
    JOIN 
        DemographicsWithLanguages d ON c.c_current_cdemo_sk = d.cd_demo_sk
    LEFT JOIN 
        SalesInfo s ON c.c_customer_sk = s.ws_bill_customer_sk
)
SELECT 
    full_address,
    cd_gender,
    primary_language,
    COALESCE(total_sales, 0) AS total_sales
FROM 
    FinalOutput
ORDER BY 
    total_sales DESC
LIMIT 100;
