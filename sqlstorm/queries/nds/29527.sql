
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
CombinedData AS (
    SELECT 
        ci.customer_name,
        ci.ca_city,
        ci.ca_state,
        ci.cd_gender,
        sd.total_sales,
        sd.order_count
    FROM 
        CustomerInfo ci
    JOIN 
        SalesData sd ON ci.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    cd.customer_name,
    cd.ca_city,
    cd.ca_state,
    cd.cd_gender,
    CASE 
        WHEN cd.total_sales IS NULL THEN 'No sales'
        WHEN cd.total_sales < 100 THEN 'Low spender'
        WHEN cd.total_sales BETWEEN 100 AND 500 THEN 'Medium spender'
        ELSE 'High spender'
    END AS spending_category,
    cd.order_count
FROM 
    CombinedData cd
ORDER BY 
    cd.total_sales DESC
LIMIT 100;
