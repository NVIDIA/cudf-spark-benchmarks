
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_marital_status,
        cd.cd_gender,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
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
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    WHERE 
        ws.ws_ship_date_sk > 0
    GROUP BY 
        ws.ws_bill_customer_sk
),
AggregatedData AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        ci.cd_marital_status,
        ci.cd_gender,
        ci.cd_credit_rating,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(sd.total_orders, 0) AS total_orders
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        SalesData sd ON ci.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    cd_marital_status,
    cd_gender,
    cd_credit_rating,
    total_sales,
    total_orders,
    CASE 
        WHEN total_sales = 0 THEN 'No Sales'
        WHEN total_sales < 500 THEN 'Low'
        WHEN total_sales BETWEEN 500 AND 1000 THEN 'Medium'
        ELSE 'High'
    END AS sales_category
FROM 
    AggregatedData
ORDER BY 
    total_sales DESC;
