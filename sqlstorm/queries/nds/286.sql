
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_net_profit > 0
),
HighValueItems AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.ws_sales_price * rs.ws_quantity) AS total_sales_value
    FROM 
        RankedSales rs
    WHERE 
        rs.rank <= 5
    GROUP BY 
        rs.ws_item_sk
),
StoreSalesSummary AS (
    SELECT 
        ss.ss_store_sk,
        COUNT(ss.ss_ticket_number) AS total_transactions,
        SUM(ss.ss_net_paid) AS total_net_paid,
        AVG(ss.ss_sales_price) AS avg_sales_price
    FROM 
        store_sales ss
    WHERE 
        ss.ss_sold_date_sk BETWEEN 1 AND 730
    GROUP BY 
        ss.ss_store_sk
)
SELECT 
    s.s_store_id,
    s.s_store_name,
    COALESCE(hv.total_sales_value, 0) AS total_value_generated,
    COALESCE(ss.total_transactions, 0) AS total_store_transactions,
    COALESCE(ss.total_net_paid, 0) AS total_net_received,
    CASE 
        WHEN ss.avg_sales_price IS NOT NULL THEN 
            ROUND(ss.total_net_paid / NULLIF(ss.total_transactions, 0), 2)
        ELSE 
            0.00 
    END AS avg_value_per_transaction
FROM 
    store s
LEFT JOIN 
    HighValueItems hv ON s.s_store_sk = hv.ws_item_sk
LEFT JOIN 
    StoreSalesSummary ss ON s.s_store_sk = ss.ss_store_sk
WHERE 
    s.s_state IN ('CA', 'NY') 
    AND (ss.total_transactions > 0 OR hv.total_sales_value > 0)
ORDER BY 
    total_value_generated DESC, total_store_transactions DESC;
