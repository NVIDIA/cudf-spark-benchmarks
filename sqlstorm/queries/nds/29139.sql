
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ca.ca_zip
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_gender = 'F'
),
WebSiteSales AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
Results AS (
    SELECT 
        cd.full_name,
        cd.full_address,
        cd.ca_city,
        cd.ca_state,
        cd.ca_country,
        cd.ca_zip,
        COALESCE(ws.total_sales, 0) AS total_sales
    FROM 
        CustomerDetails cd
    LEFT JOIN 
        WebSiteSales ws ON cd.c_customer_sk = ws.ws_bill_customer_sk
)
SELECT 
    full_name,
    full_address,
    ca_city,
    ca_state,
    ca_country,
    ca_zip,
    total_sales,
    CASE 
        WHEN total_sales > 1000 THEN 'High Value Customer'
        WHEN total_sales > 500 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value
FROM 
    Results
ORDER BY 
    total_sales DESC;
