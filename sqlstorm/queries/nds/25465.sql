
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender, cd.cd_marital_status ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
ProcessedAddresses AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type, 
               CASE WHEN ca.ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca.ca_suite_number) END, 
               ', ', ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip) AS full_address
    FROM 
        customer_address ca
),
SalesSummary AS (
    SELECT 
        ws.ws_web_site_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_web_site_sk
),
FinalBenchmark AS (
    SELECT 
        rc.full_name,
        rc.cd_gender,
        rc.cd_marital_status,
        rc.cd_education_status,
        pa.full_address,
        ss.total_orders,
        ss.total_sales
    FROM 
        RankedCustomers rc
    JOIN 
        ProcessedAddresses pa ON rc.c_customer_sk = pa.ca_address_sk
    JOIN 
        SalesSummary ss ON rc.c_customer_sk = ss.ws_web_site_sk
    WHERE 
        rc.rank <= 10
)
SELECT 
    CONCAT(full_name, ' - ', cd_gender, ', ', cd_marital_status, ', ', cd_education_status) AS customer_details,
    full_address,
    total_orders,
    total_sales
FROM 
    FinalBenchmark
ORDER BY 
    total_sales DESC;
