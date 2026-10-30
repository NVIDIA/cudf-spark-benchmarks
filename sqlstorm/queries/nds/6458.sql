WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk, 
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        COUNT(DISTINCT ws.ws_web_page_sk) AS web_page_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2452959 AND 2452965 
    GROUP BY 
        c.c_customer_sk
), 
SalesAnalysis AS (
    SELECT 
        cs.c_customer_sk, 
        cs.total_profit, 
        cs.order_count,
        CASE 
            WHEN cs.order_count = 0 THEN 0 
            ELSE cs.total_profit / cs.order_count 
        END AS avg_order_profit
    FROM 
        CustomerSales cs
)
SELECT 
    c.c_first_name, 
    c.c_last_name, 
    sa.total_profit, 
    sa.order_count, 
    sa.avg_order_profit
FROM 
    customer c
JOIN 
    SalesAnalysis sa ON c.c_customer_sk = sa.c_customer_sk
WHERE 
    sa.total_profit > (SELECT AVG(total_profit) FROM CustomerSales) 
    AND c.c_birth_year BETWEEN 1980 AND 1990
ORDER BY 
    sa.total_profit DESC
LIMIT 100;