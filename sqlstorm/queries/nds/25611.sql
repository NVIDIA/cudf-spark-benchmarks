
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_paid) AS total_sales
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
DetailedSales AS (
    SELECT 
        cd.full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.ca_city,
        cd.ca_state,
        cd.ca_country,
        COALESCE(sd.total_sales, 0) AS total_sales
    FROM 
        CustomerDetails cd
    LEFT JOIN 
        SalesData sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    ds.full_name,
    ds.cd_gender,
    ds.cd_marital_status,
    ds.cd_education_status,
    ds.cd_purchase_estimate,
    ds.ca_city,
    ds.ca_state,
    ds.ca_country,
    CASE 
        WHEN ds.total_sales > 1000 THEN 'High Value Customer'
        WHEN ds.total_sales BETWEEN 500 AND 1000 THEN 'Mid Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value_category
FROM 
    DetailedSales ds
WHERE 
    ds.cd_marital_status = 'M'
ORDER BY 
    ds.total_sales DESC
LIMIT 100;
