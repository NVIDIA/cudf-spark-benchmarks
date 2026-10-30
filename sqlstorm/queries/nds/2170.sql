WITH BaseSales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_paid_inc_tax,
        ws.ws_ext_sales_price,
        CASE
            WHEN ws.ws_quantity > 10 THEN 'Bulk'
            WHEN ws.ws_quantity BETWEEN 5 AND 10 THEN 'Moderate'
            ELSE 'Retail'
        END AS Sales_Category,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_paid_inc_tax DESC) as Sales_Rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 2458855 AND 2458880  
), RankedSales AS (
    SELECT
        bs.*,
        COALESCE(sr.sr_return_quantity, 0) as total_returns
    FROM BaseSales bs
    LEFT JOIN store_returns sr ON bs.ws_item_sk = sr.sr_item_sk AND bs.ws_order_number = sr.sr_ticket_number
)
SELECT
    rs.ws_item_sk,
    COUNT(rs.ws_order_number) AS order_count,
    SUM(rs.ws_quantity) AS total_quantity_sold,
    SUM(rs.ws_net_paid_inc_tax) AS total_sales,
    AVG(rs.ws_ext_sales_price) AS avg_sales_price,
    MAX(rs.total_returns) AS max_returns,
    MIN(rs.total_returns) AS min_returns,
    CASE
        WHEN AVG(rs.ws_ext_sales_price) > 100 THEN 'High Value'
        ELSE 'Standard Value'
    END AS Value_Category
FROM RankedSales rs
WHERE rs.Sales_Rank = 1  
GROUP BY rs.ws_item_sk
ORDER BY total_sales DESC
LIMIT 10;