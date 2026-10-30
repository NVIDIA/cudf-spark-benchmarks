
WITH  sales_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        w.w_warehouse_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        customer c
    INNER JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    INNER JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE 
        w.w_state = 'CA' 
        AND ws.ws_sold_date_sk BETWEEN 2400 AND 2450
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, w.w_warehouse_sk
), ranked_sales AS (
    SELECT 
        c_customer_sk AS customer_sk,
        c_first_name,
        c_last_name,
        total_net_profit,
        order_count,
        rank
    FROM 
        sales_data
    WHERE 
        rank <= 10
)
SELECT 
    r.customer_sk,
    r.c_first_name,
    r.c_last_name,
    COALESCE(r.total_net_profit, 0) AS total_net_profit,
    COALESCE(r.order_count, 0) AS order_count,
    (SELECT COUNT(*) 
     FROM store_sales ss 
     WHERE ss.ss_customer_sk = r.customer_sk 
       AND ss.ss_sold_date_sk BETWEEN 2400 AND 2450) AS store_order_count,
    (SELECT COALESCE(SUM(ss.ss_net_profit), 0)
     FROM store_sales ss 
     WHERE ss.ss_customer_sk = r.customer_sk 
       AND ss.ss_sold_date_sk BETWEEN 2400 AND 2450) AS store_total_profit
FROM 
    ranked_sales r
LEFT JOIN 
    (SELECT 
         DISTINCT c_current_cdemo_sk
     FROM 
         customer
     WHERE 
         c_birth_year IS NULL OR c_birth_month IS NULL) AS NULL_demo_customers ON r.customer_sk = NULL_demo_customers.c_current_cdemo_sk
WHERE 
    NULL_demo_customers.c_current_cdemo_sk IS NULL;
