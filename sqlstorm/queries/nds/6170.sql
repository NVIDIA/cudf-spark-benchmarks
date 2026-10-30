
WITH RankedSales AS (
    SELECT 
        s.s_store_id,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY SUM(ss.ss_net_profit) DESC) AS store_rank
    FROM 
        store s
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    WHERE 
        ss.ss_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        s.s_store_id
),
TopStores AS (
    SELECT 
        r.s_store_id,
        r.total_quantity,
        r.total_net_profit
    FROM 
        RankedSales r
    WHERE 
        r.store_rank <= 5
),
CustomerSales AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT ss.ss_ticket_number) AS purchase_count,
        SUM(ss.ss_net_profit) AS total_spent
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        ss.ss_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        c.c_customer_id
)
SELECT 
    ts.s_store_id,
    ts.total_quantity,
    ts.total_net_profit,
    cs.c_customer_id,
    cs.purchase_count,
    cs.total_spent
FROM 
    TopStores ts
JOIN 
    CustomerSales cs ON cs.total_spent > 1000
ORDER BY 
    ts.total_net_profit DESC, 
    cs.total_spent DESC;
