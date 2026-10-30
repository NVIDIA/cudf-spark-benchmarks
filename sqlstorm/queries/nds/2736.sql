
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) AS rnk
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2400 AND 2405
),
TotalSales AS (
    SELECT 
        ws_order_number,
        SUM(ws_quantity * ws_sales_price) AS total_sales
    FROM 
        RankedSales
    WHERE 
        rnk <= 3
    GROUP BY 
        ws_order_number
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ts.total_sales,
    CASE 
        WHEN ts.total_sales > 1000 THEN 'High Value'
        WHEN ts.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM 
    TotalSales ts
LEFT JOIN 
    CustomerInfo ci ON ts.ws_order_number = ci.c_customer_sk
WHERE 
    ci.cd_purchase_estimate IS NOT NULL
ORDER BY 
    total_sales DESC
LIMIT 10;
