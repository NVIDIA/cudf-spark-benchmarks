WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk, 
        ws.ws_order_number, 
        ws.ws_sales_price,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS profit_rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2001) - 30 
                                        AND (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2001)
),
RecentReturns AS (
    SELECT 
        wr.wr_item_sk, 
        SUM(wr.wr_return_quantity) AS total_returned_qty,
        SUM(wr.wr_return_amt) AS total_returned_amt
    FROM web_returns wr
    WHERE wr.wr_returned_date_sk IN (
        SELECT d.d_date_sk 
        FROM date_dim d 
        WHERE d.d_year = 2001 AND d.d_month_seq IN (5, 6)
    )
    GROUP BY wr.wr_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(rs.price_rank, 0) AS highest_price_rank,
    COALESCE(rs.profit_rank, 0) AS highest_profit_rank,
    COALESCE(rr.total_returned_qty, 0) AS total_qty_returned,
    COALESCE(rr.total_returned_amt, 0) AS total_amt_returned,
    (SELECT COUNT(*) 
     FROM customer c 
     WHERE c.c_current_cdemo_sk IS NOT NULL 
         AND EXISTS (SELECT 1 FROM customer_demographics cd WHERE cd.cd_demo_sk = c.c_current_cdemo_sk AND cd.cd_gender = 'F')
    ) AS female_customer_count
FROM item i
LEFT JOIN RankedSales rs ON i.i_item_sk = rs.ws_item_sk AND rs.price_rank = 1
LEFT JOIN RecentReturns rr ON i.i_item_sk = rr.wr_item_sk
WHERE i.i_current_price > (
    SELECT AVG(i2.i_current_price) 
    FROM item i2 
    WHERE i2.i_rec_start_date < cast('2002-10-01' as date) 
        AND i2.i_rec_end_date IS NULL
) 
AND (SELECT COUNT(*) 
     FROM inventory inv 
     WHERE inv.inv_item_sk = i.i_item_sk AND inv.inv_quantity_on_hand > 0) > 0
ORDER BY total_qty_returned DESC, highest_profit_rank ASC;