
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(ws.ws_net_paid_inc_tax) AS avg_order_value
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_sk
),
StoreSales AS (
    SELECT 
        s.s_store_sk,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_sales,
        SUM(ss.ss_net_profit) AS total_store_profit
    FROM 
        store s
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    WHERE 
        s.s_number_employees > 50
    GROUP BY 
        s.s_store_sk
),
DateFiltered AS (
    SELECT 
        d.d_date_sk,
        SUM(ws.ws_net_profit) AS daily_profit
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE 
        d.d_year = 2001 AND d.d_dow NOT IN (6, 7) 
    GROUP BY 
        d.d_date_sk
)
SELECT 
    cs.c_customer_sk, 
    cs.total_orders, 
    cs.total_profit, 
    cs.avg_order_value,
    ss.total_sales AS store_total_sales,
    ss.total_store_profit,
    df.daily_profit
FROM 
    CustomerSales cs
JOIN 
    StoreSales ss ON cs.total_orders = ss.total_sales
JOIN 
    DateFiltered df ON df.daily_profit > 0
ORDER BY 
    cs.total_profit DESC, 
    ss.total_store_profit DESC
LIMIT 100;
