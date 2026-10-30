
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank,
        SUM(ws.ws_quantity) OVER (PARTITION BY ws.ws_item_sk) AS total_quantity
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
),
HighValueSales AS (
    SELECT 
        r.ws_item_sk,
        r.ws_order_number,
        r.ws_sales_price,
        r.total_quantity,
        CASE 
            WHEN r.price_rank = 1 THEN 'High'
            WHEN r.price_rank = 2 THEN 'Medium'
            ELSE 'Low'
        END AS value_category
    FROM 
        RankedSales r
    WHERE 
        r.total_quantity > 50
),
StoreData AS (
    SELECT 
        s.s_store_sk,
        AVG(ss.ss_net_profit) AS avg_store_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_sales_records
    FROM 
        store s
    LEFT JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s.s_store_sk
)
SELECT 
    hvs.ws_item_sk,
    hvs.ws_order_number,
    hvs.ws_sales_price,
    hvs.total_quantity,
    hvs.value_category,
    sd.avg_store_profit,
    sd.total_sales_records
FROM 
    HighValueSales hvs
JOIN 
    StoreData sd ON hvs.ws_item_sk = sd.s_store_sk 
WHERE 
    sd.avg_store_profit IS NOT NULL
    AND hvs.ws_sales_price > (
        SELECT 
            AVG(ws_sales_price) 
        FROM 
            web_sales 
        WHERE 
            ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    )
ORDER BY 
    hvs.ws_item_sk,
    hvs.ws_order_number;
