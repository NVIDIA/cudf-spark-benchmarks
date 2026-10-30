
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesAggregates AS (
    SELECT
        cd.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        CustomerDetails cd ON ws.ws_bill_customer_sk = cd.c_customer_sk
    GROUP BY 
        cd.c_customer_sk
)
SELECT 
    cd.full_name,
    cd.ca_city,
    cd.ca_state,
    cd.ca_zip,
    sa.total_sales,
    sa.total_orders,
    CASE 
        WHEN sa.total_sales > 1000 THEN 'Platinum'
        WHEN sa.total_sales BETWEEN 500 AND 1000 THEN 'Gold'
        WHEN sa.total_sales BETWEEN 100 AND 499 THEN 'Silver'
        ELSE 'Bronze'
    END AS customer_tier
FROM 
    CustomerDetails cd
LEFT JOIN 
    SalesAggregates sa ON cd.c_customer_sk = sa.c_customer_sk
WHERE 
    cd.ca_state = 'CA' 
ORDER BY 
    total_sales DESC, full_name ASC
LIMIT 100;
