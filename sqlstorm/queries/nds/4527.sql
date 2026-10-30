
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
        ws.ws_sold_date_sk = (
            SELECT MAX(d_date_sk) 
            FROM date_dim 
            WHERE d_date = '2002-10-01'
        )
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
AggregatedSales AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_profit,
        cs.order_count,
        DENSE_RANK() OVER (ORDER BY cs.total_profit DESC) AS profit_rank
    FROM 
        CustomerSales cs
)
SELECT 
    asales.c_first_name,
    asales.c_last_name,
    asales.total_profit,
    asales.order_count,
    CASE 
        WHEN asales.total_profit IS NULL THEN 'No Profit'
        ELSE 'Profitable'
    END AS profit_status,
    COALESCE((SELECT COUNT(*) 
              FROM store_sales ss 
              WHERE ss.ss_customer_sk = asales.c_customer_sk 
              AND ss.ss_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = EXTRACT(YEAR FROM DATE '2002-10-01') - 1)
              AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = EXTRACT(YEAR FROM DATE '2002-10-01'))), 0) AS store_orders_last_year
FROM 
    AggregatedSales asales
WHERE 
    asales.profit_rank <= 10
ORDER BY 
    asales.total_profit DESC;
