
WITH RankedSales AS (
    SELECT 
        s_sales.ss_store_sk,
        s_sales.ss_sold_date_sk,
        SUM(s_sales.ss_quantity) AS total_quantity,
        SUM(s_sales.ss_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY s_sales.ss_store_sk ORDER BY SUM(s_sales.ss_net_profit) DESC) AS rank_profit,
        RANK() OVER (PARTITION BY s_sales.ss_store_sk ORDER BY SUM(s_sales.ss_quantity) DESC) AS rank_quantity
    FROM 
        store_sales s_sales
    JOIN 
        customer c ON s_sales.ss_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON s_sales.ss_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 AND 
        c.c_preferred_cust_flag = 'Y'
    GROUP BY 
        s_sales.ss_store_sk, s_sales.ss_sold_date_sk
),
TopStoreSales AS (
    SELECT 
        rs.ss_store_sk,
        rs.ss_sold_date_sk,
        rs.total_quantity,
        rs.total_profit
    FROM 
        RankedSales rs
    WHERE 
        rs.rank_profit <= 3 OR rs.rank_quantity <= 3
)
SELECT 
    w.w_warehouse_id,
    w.w_warehouse_name,
    ts.total_quantity,
    ts.total_profit
FROM 
    TopStoreSales ts
JOIN 
    warehouse w ON ts.ss_store_sk = w.w_warehouse_sk
ORDER BY 
    ts.total_profit DESC, ts.total_quantity DESC;
