
WITH CustomerSaleSummary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighValueCustomers AS (
    SELECT 
        css.c_customer_sk,
        css.c_first_name,
        css.c_last_name,
        css.total_profit,
        css.total_orders,
        RANK() OVER (ORDER BY css.total_profit DESC) AS profit_rank
    FROM 
        CustomerSaleSummary css
    WHERE 
        css.total_profit > (SELECT AVG(total_profit) FROM CustomerSaleSummary)
),
StoreSalesDetails AS (
    SELECT 
        ss.ss_customer_sk,
        SUM(ss.ss_net_profit) AS store_total_profit,
        COUNT(ss.ss_ticket_number) AS total_store_orders
    FROM 
        store_sales ss
    GROUP BY 
        ss.ss_customer_sk
),
CombinedSales AS (
    SELECT 
        hvc.c_customer_sk,
        hvc.c_first_name,
        hvc.c_last_name,
        hvc.total_profit + COALESCE(ss.store_total_profit, 0) AS combined_total_profit,
        hvc.total_orders + COALESCE(ss.total_store_orders, 0) AS combined_total_orders
    FROM 
        HighValueCustomers hvc
    LEFT JOIN 
        StoreSalesDetails ss ON hvc.c_customer_sk = ss.ss_customer_sk
)
SELECT 
    cb.c_customer_sk,
    CONCAT(cb.c_first_name, ' ', cb.c_last_name) AS customer_name,
    cb.combined_total_profit,
    cb.combined_total_orders,
    CASE 
        WHEN cb.combined_total_profit > 1000 THEN 'Gold'
        WHEN cb.combined_total_profit BETWEEN 500 AND 1000 THEN 'Silver'
        ELSE 'Bronze'
    END AS customer_level
FROM 
    CombinedSales cb
ORDER BY 
    cb.combined_total_profit DESC
LIMIT 10;
