
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ws_quantity,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS price_rank
    FROM web_sales
    WHERE ws_sales_price IS NOT NULL
), TotalSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price * ws_quantity) AS total_revenue
    FROM web_sales
    GROUP BY ws_item_sk
), LastYearSales AS (
    SELECT 
        cs_item_sk,
        SUM(cs_ext_sales_price) AS last_year_revenue
    FROM catalog_sales
    WHERE cs_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_year = EXTRACT(YEAR FROM DATE '2002-10-01') - 1 AND d_month_seq = 12)
      AND (SELECT d_date_sk FROM date_dim WHERE d_year = EXTRACT(YEAR FROM DATE '2002-10-01') AND d_month_seq = 1) 
    GROUP BY cs_item_sk
), InventoryStatus AS (
    SELECT 
        inv_item_sk,
        inv_quantity_on_hand,
        CASE 
            WHEN inv_quantity_on_hand < 5 THEN 'Low Stock'
            WHEN inv_quantity_on_hand BETWEEN 5 AND 20 THEN 'Moderate Stock'
            ELSE 'Sufficient Stock'
        END AS stock_level
    FROM inventory
), FinalReport AS (
    SELECT 
        it.i_item_id,
        it.i_item_desc,
        ts.total_revenue,
        COALESCE(ly.last_year_revenue, 0) AS last_year_revenue,
        CASE 
            WHEN ts.total_revenue - COALESCE(ly.last_year_revenue, 0) > 0 THEN 'Increased'
            WHEN ts.total_revenue - COALESCE(ly.last_year_revenue, 0) < 0 THEN 'Decreased'
            ELSE 'No Change'
        END AS sales_trend,
        COALESCE(stock.stock_level, 'Out of Stock') AS current_stock_status
    FROM item it
    LEFT JOIN TotalSales ts ON it.i_item_sk = ts.ws_item_sk
    LEFT JOIN LastYearSales ly ON it.i_item_sk = ly.cs_item_sk
    LEFT JOIN InventoryStatus stock ON it.i_item_sk = stock.inv_item_sk
    WHERE it.i_current_price > (
        SELECT AVG(i_current_price) 
        FROM item
    ) 
    AND (SELECT COUNT(*) FROM web_returns WHERE wr_item_sk = it.i_item_sk) < 2
)
SELECT 
    *,
    CASE 
        WHEN total_revenue IS NULL THEN 'No Sales Data'
        WHEN sales_trend = 'Increased' AND current_stock_status = 'Low Stock' THEN 'Urgent Replenishment Needed'
        ELSE 'Status Normal'
    END AS final_status
FROM FinalReport
WHERE total_revenue > 5000
ORDER BY total_revenue DESC
LIMIT 10;
