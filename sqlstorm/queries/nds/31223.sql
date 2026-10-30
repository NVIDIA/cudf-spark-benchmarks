
WITH  SalesTrend AS (
    SELECT 
        ws_sold_date_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (ORDER BY ws_sold_date_sk) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
    GROUP BY 
        ws_sold_date_sk
), 
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws_order_number) AS order_count,
        SUM(ws_net_paid) AS total_spent,
        MAX(ws_sold_date_sk) AS last_purchase_date
    FROM 
        customer c
        LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
TotalSales AS (
    SELECT 
        SUM(ws_sales_price) AS grand_total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
)
SELECT 
    cs.c_customer_sk,
    cs.order_count,
    cs.total_spent,
    dt.total_quantity,
    dt.total_sales,
    ts.grand_total_sales,
    ts.total_orders,
    CASE 
        WHEN cs.last_purchase_date IS NULL THEN 'No Purchases'
        ELSE 
            CASE 
                WHEN cs.total_spent >= 500 THEN 'High Value'
                WHEN cs.total_spent BETWEEN 100 AND 500 THEN 'Medium Value'
                ELSE 'Low Value'
            END 
    END AS customer_value_segment
FROM 
    CustomerStats cs
JOIN 
    (SELECT SUM(total_quantity) AS total_quantity, SUM(total_sales) AS total_sales FROM SalesTrend) dt ON 1=1
CROSS JOIN 
    TotalSales ts
WHERE 
    cs.order_count > 0
ORDER BY 
    cs.total_spent DESC;
