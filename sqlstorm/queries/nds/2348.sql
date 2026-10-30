
WITH SalesSummary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM web_sales
    WHERE ws_sold_date_sk IN (
        SELECT d_date_sk 
        FROM date_dim 
        WHERE d_year = 2023
    )
    GROUP BY ws_item_sk
),
HighSalesItems AS (
    SELECT 
        ss.ws_item_sk,
        ss.total_quantity,
        ss.total_sales,
        ss.order_count,
        i.i_item_desc,
        ROW_NUMBER() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
    FROM SalesSummary ss
    JOIN item i ON ss.ws_item_sk = i.i_item_sk
    WHERE ss.total_sales > 1000
),
StoreInfo AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        w.w_warehouse_sk,
        w.w_warehouse_name,
        CASE 
            WHEN s.s_number_employees > 100 THEN 'Large'
            ELSE 'Small'
        END AS store_size
    FROM store s
    LEFT JOIN warehouse w ON s.s_market_id = w.w_warehouse_sk
    WHERE s.s_state = 'NY'
)
SELECT 
    hsi.i_item_desc,
    hsi.total_quantity,
    hsi.total_sales,
    si.s_store_name,
    si.store_size,
    COUNT(CASE WHEN sr_return_quantity IS NOT NULL THEN 1 END) AS return_count,
    AVG(sr_return_amt) AS avg_return_amt
FROM HighSalesItems hsi
JOIN store_sales ss ON hsi.ws_item_sk = ss.ss_item_sk 
LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
JOIN StoreInfo si ON ss.ss_store_sk = si.s_store_sk
WHERE hsi.sales_rank <= 10
GROUP BY 
    hsi.i_item_desc,
    hsi.total_quantity,
    hsi.total_sales,
    si.s_store_name,
    si.store_size
ORDER BY hsi.total_sales DESC;
