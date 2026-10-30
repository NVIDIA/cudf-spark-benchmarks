
WITH CustomerDetails AS (
    SELECT 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        c.c_email_address,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        aa.ca_city,
        aa.ca_state,
        aa.ca_country,
        c.c_customer_sk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address aa ON c.c_current_addr_sk = aa.ca_address_sk
    WHERE 
        cd.cd_purchase_estimate > 1000
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_bill_customer_sk IS NOT NULL
    GROUP BY 
        ws_bill_customer_sk
),
CombinedData AS (
    SELECT 
        cd.full_name,
        cd.c_email_address,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.ca_city,
        cd.ca_state,
        cd.ca_country,
        sd.total_sales,
        sd.order_count
    FROM 
        CustomerDetails cd
    LEFT JOIN 
        SalesData sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    CombinedData.*,
    CASE 
        WHEN CombinedData.total_sales IS NULL THEN 'No Sales'
        WHEN CombinedData.total_sales > 10000 THEN 'High Value Customer'
        WHEN CombinedData.total_sales BETWEEN 5000 AND 10000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value_category
FROM 
    CombinedData
ORDER BY 
    total_sales DESC;
