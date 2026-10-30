
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_web_page_sk) AS distinct_web_pages
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1985 AND 2000
    GROUP BY 
        c.c_customer_id
),
HighValueCustomers AS (
    SELECT 
        csc.c_customer_id,
        csc.total_net_profit,
        csc.total_orders,
        csc.distinct_web_pages
    FROM 
        CustomerSales csc
    WHERE 
        csc.total_net_profit > (SELECT AVG(total_net_profit) FROM CustomerSales)
),
DateSales AS (
    SELECT 
        dd.d_date,
        SUM(ws.ws_net_profit) AS daily_net_profit
    FROM 
        date_dim dd
    JOIN 
        web_sales ws ON dd.d_date_sk = ws.ws_sold_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        dd.d_date
)
SELECT 
    hvc.c_customer_id,
    hvc.total_net_profit,
    hvc.total_orders,
    hvc.distinct_web_pages,
    ds.d_date,
    ds.daily_net_profit
FROM 
    HighValueCustomers hvc
JOIN 
    DateSales ds ON ds.daily_net_profit > 1000
ORDER BY 
    hvc.total_net_profit DESC, ds.d_date ASC
LIMIT 50;
