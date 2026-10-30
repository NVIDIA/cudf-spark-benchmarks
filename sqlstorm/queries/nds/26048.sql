
WITH CustomerData AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_gender = 'F'
        AND ca.ca_country = 'USA'
),
WebSalesData AS (
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
        cd.full_name,
        cd.ca_city,
        cd.ca_state,
        cd.ca_country,
        wd.total_sales,
        wd.order_count
    FROM 
        CustomerData cd
    LEFT JOIN 
        WebSalesData wd ON cd.c_customer_sk = wd.ws_bill_customer_sk
)
SELECT 
    full_name,
    ca_city AS city,
    ca_state AS state,
    ca_country AS country,
    COALESCE(total_sales, 0) AS total_sales,
    COALESCE(order_count, 0) AS order_count,
    CASE 
        WHEN COALESCE(total_sales, 0) > 1000 THEN 'High Value'
        WHEN COALESCE(total_sales, 0) BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value
FROM 
    CombinedData
ORDER BY 
    customer_value DESC, 
    total_sales DESC;
