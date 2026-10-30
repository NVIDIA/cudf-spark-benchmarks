WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk, 
        ws.ws_order_number,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS sales_rank,
        SUM(ws.ws_quantity) OVER (PARTITION BY ws.ws_item_sk) AS total_quantity,
        MAX(ws.ws_net_paid) OVER (PARTITION BY ws.ws_item_sk) AS max_net_paid
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE c.c_birth_year BETWEEN 1970 AND 1990
      AND (c.c_current_cdemo_sk IS NOT NULL OR c.c_current_hdemo_sk IS NOT NULL)
)

SELECT 
    item.i_item_id, 
    item.i_item_desc, 
    COALESCE(rs.total_quantity, 0) AS total_quantity_sold,
    COALESCE(rs.max_net_paid, 0.00) AS highest_net_paid,
    COALESCE(sr.return_quantity, 0) AS total_returns,
    CASE 
        WHEN rs.total_quantity IS NULL THEN 'No Sales'
        WHEN COALESCE(sr.return_quantity, 0) > 0 THEN 'Contains Returns'
        ELSE 'Successful Sales'
    END AS sales_status
FROM item 
LEFT JOIN RankedSales rs ON item.i_item_sk = rs.ws_item_sk
LEFT JOIN (
    SELECT 
        cr_item_sk, 
        SUM(cr_return_quantity) AS return_quantity
    FROM catalog_returns
    GROUP BY cr_item_sk
) sr ON item.i_item_sk = sr.cr_item_sk
WHERE item.i_current_price IS NOT NULL
  AND item.i_rec_start_date <= cast('2002-10-01' as date)
  AND (item.i_rec_end_date IS NULL OR item.i_rec_end_date >= cast('2002-10-01' as date))
ORDER BY sales_status DESC, total_quantity_sold DESC;