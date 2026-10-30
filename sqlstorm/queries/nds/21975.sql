
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS price_rank,
        SUM(ws_sales_price) OVER (PARTITION BY ws_item_sk) AS total_sales
    FROM 
        web_sales
    WHERE 
        ws_sales_price IS NOT NULL
),
SalesSummary AS (
    SELECT 
        ws_item_sk,
        AVG(ws_sales_price) AS avg_sales_price,
        COUNT(*) AS total_orders,
        MAX(total_sales) AS max_total_sales
    FROM 
        RankedSales
    GROUP BY 
        ws_item_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.d_date,
        SUM(ws.ws_sales_price) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, d.d_date
),
CombinedResults AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ss.avg_sales_price,
        ss.total_orders,
        COALESCE(ss.max_total_sales, 0) AS max_total_sales,
        ci.total_spent
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        SalesSummary ss ON ci.c_customer_sk = ss.ws_item_sk
)
SELECT 
    cr.c_customer_sk,
    cr.c_first_name,
    cr.c_last_name,
    cr.avg_sales_price,
    cr.total_orders,
    cr.max_total_sales,
    cr.total_spent
FROM 
    CombinedResults cr
WHERE 
    (cr.avg_sales_price < 50 OR cr.total_orders > 10)
    AND cr.total_spent < (SELECT AVG(total_spent) FROM CustomerInfo)
UNION ALL
SELECT 
    ca.c_customer_sk,
    ca.c_first_name,
    ca.c_last_name,
    NULL AS avg_sales_price,
    NULL AS total_orders,
    NULL AS max_total_sales,
    SUM(ws.ws_sales_price) AS total_spent
FROM 
    customer ca
LEFT JOIN 
    web_sales ws ON ca.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    ws.ws_sales_price IS NOT NULL
GROUP BY 
    ca.c_customer_sk, ca.c_first_name, ca.c_last_name
HAVING 
    COUNT(ws.ws_order_number) > 10 AND
    SUM(ws.ws_sales_price) > 1000
ORDER BY 
    1, 3 DESC;
