
WITH Address AS (
    SELECT 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(', Suite ', ca_suite_number) END) AS full_address,
        ca_city,
        ca_state,
        CONCAT(ca_zip, ' ', ca_country) AS zip_country,
        ca_address_sk
    FROM 
        customer_address
),
Demographics AS (
    SELECT 
        CASE 
            WHEN cd_gender = 'M' THEN 'Male' 
            WHEN cd_gender = 'F' THEN 'Female' 
            ELSE 'Other' 
        END AS gender,
        cd_marital_status AS marital_status,
        cd_education_status AS education_status,
        cd_purchase_estimate AS purchase_estimate,
        cd_demo_sk
    FROM 
        customer_demographics
),
Sales AS (
    SELECT 
        'Web' AS source,
        ws_ship_date_sk AS date_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_ship_date_sk
    UNION ALL
    SELECT 
        'Store' AS source,
        ss_sold_date_sk AS date_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_net_paid) AS total_sales
    FROM 
        store_sales
    GROUP BY 
        ss_sold_date_sk
),
SalesInfo AS (
    SELECT 
        d.d_date AS sales_date,
        s.source,
        s.total_quantity,
        s.total_sales,
        d.d_month_seq,
        d.d_year
    FROM 
        Sales s
    JOIN 
        date_dim d ON s.date_sk = d.d_date_sk
)
SELECT 
    a.full_address,
    a.ca_city,
    a.ca_state,
    d.gender,
    d.marital_status,
    d.education_status,
    d.purchase_estimate,
    si.sales_date,
    si.source,
    si.total_quantity,
    si.total_sales
FROM 
    Address a
JOIN 
    customer c ON c.c_current_addr_sk = a.ca_address_sk
JOIN 
    Demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
JOIN 
    SalesInfo si ON si.source IN ('Web', 'Store')
WHERE 
    a.ca_state = 'CA' AND 
    d.purchase_estimate > 1000
ORDER BY 
    si.sales_date DESC, 
    si.total_sales DESC
LIMIT 100;
