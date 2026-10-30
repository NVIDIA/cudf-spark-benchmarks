
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_bill_customer_sk
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        r.total_sales
    FROM 
        customer c
    JOIN 
        RankedSales r ON c.c_customer_sk = r.ws_bill_customer_sk
    WHERE 
        r.rank <= 10
)
SELECT 
    hvc.c_customer_sk,
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.total_sales,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    AVG(ws.ws_net_profit) AS avg_net_profit
FROM 
    HighValueCustomers hvc
JOIN 
    web_sales ws ON hvc.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY 
    hvc.c_customer_sk, hvc.c_first_name, hvc.c_last_name, hvc.total_sales
ORDER BY 
    hvc.total_sales DESC;
