
WITH RankedSales AS (
    SELECT 
        ss_store_sk,
        ss_item_sk,
        ss_sales_price,
        ss_quantity,
        RANK() OVER (PARTITION BY ss_store_sk ORDER BY ss_sales_price DESC) AS rank_price,
        ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY ss_quantity DESC) AS row_qty
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk BETWEEN 1 AND 100
),
StoreMetrics AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        COALESCE(SUM(ss.ss_net_profit), 0) AS total_net_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions
    FROM 
        store s
    LEFT JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s.s_store_sk, s.s_store_name
),
TopItems AS (
    SELECT 
        rs.ss_store_sk,
        rs.ss_item_sk,
        SUM(rs.ss_quantity) AS total_quantity_sold
    FROM 
        RankedSales rs
    WHERE 
        rs.rank_price <= 10 AND rs.row_qty <= 5
    GROUP BY 
        rs.ss_store_sk, rs.ss_item_sk
)
SELECT 
    sm.s_store_name,
    ti.ss_item_sk,
    ti.total_quantity_sold,
    sm.total_net_profit,
    (CASE 
        WHEN sm.total_transactions > 0 THEN sm.total_net_profit / sm.total_transactions
        ELSE NULL 
    END) AS avg_profit_per_transaction,
    (SELECT 
        COUNT(DISTINCT ws.ws_order_number) 
     FROM 
        web_sales ws 
     WHERE 
        ws.ws_ship_date_sk BETWEEN 1 AND 100 
        AND ws.ws_item_sk = ti.ss_item_sk 
        AND ws.ws_net_paid > sm.total_net_profit * 0.8) AS related_web_sales
FROM 
    StoreMetrics sm
JOIN 
    TopItems ti ON sm.s_store_sk = ti.ss_store_sk
WHERE 
    sm.total_net_profit > 0 AND ti.total_quantity_sold IS NOT NULL
ORDER BY 
    sm.total_net_profit DESC, ti.total_quantity_sold DESC;
