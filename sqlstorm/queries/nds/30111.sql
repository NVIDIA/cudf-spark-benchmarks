
WITH  CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        SUM(COALESCE(ss.ss_net_profit, 0) + COALESCE(ws.ws_net_profit, 0) - COALESCE(cr.cr_net_loss, 0)) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(COALESCE(ss.ss_net_profit, 0) + COALESCE(ws.ws_net_profit, 0) - COALESCE(cr.cr_net_loss, 0)) DESC) AS rank
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN 
        (SELECT cr_returning_customer_sk, SUM(cr_net_loss) AS cr_net_loss 
         FROM catalog_returns 
         GROUP BY cr_returning_customer_sk) cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_customer_id
), 
TopCustomers AS (
    SELECT 
        c_customer_id, 
        total_profit 
    FROM 
        CustomerSales 
    WHERE 
        rank <= 10
)
SELECT 
    tc.c_customer_id,
    tc.total_profit,
    CASE 
        WHEN total_profit > 1000 THEN 'High Value'
        WHEN total_profit BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value' 
    END AS customer_value_category
FROM 
    TopCustomers tc
INNER JOIN 
    (SELECT DISTINCT d_year, d_month_seq FROM date_dim WHERE d_year = 2023 AND d_month_seq BETWEEN 1 AND 12) dd ON 1=1
ORDER BY 
    total_profit DESC;
