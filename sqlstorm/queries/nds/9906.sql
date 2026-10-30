
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        c.c_birth_year BETWEEN 1980 AND 1990
        AND ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
StoreSales AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS sale_count
    FROM 
        store s
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    WHERE 
        ss.ss_sold_date_sk >= (SELECT MIN(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2021)
    GROUP BY 
        s.s_store_sk, s.s_store_name
),
TotalSales AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        ss.s_store_sk,
        ss.s_store_name,
        cs.total_profit,
        cs.order_count,
        ss.total_net_profit,
        ss.sale_count
    FROM 
        CustomerSales cs
    JOIN 
        StoreSales ss ON cs.total_profit > ss.total_net_profit
)
SELECT 
    ts.c_first_name, 
    ts.c_last_name, 
    ts.s_store_name, 
    ts.total_profit, 
    ts.total_net_profit 
FROM 
    TotalSales ts
JOIN 
    customer c ON ts.c_customer_sk = c.c_customer_sk
JOIN 
    store s ON ts.s_store_sk = s.s_store_sk
ORDER BY 
    ts.total_profit DESC, 
    ts.total_net_profit DESC
LIMIT 10;
