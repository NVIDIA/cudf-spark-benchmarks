
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rank_within_item
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) - 30 FROM date_dim d)
        AND ws.ws_net_paid > (SELECT AVG(ws_inner.ws_net_paid) FROM web_sales ws_inner WHERE ws_inner.ws_item_sk = ws.ws_item_sk)
),
TopSales AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.ws_ext_sales_price) AS total_sales,
        SUM(rs.ws_net_profit) AS total_profit
    FROM 
        RankedSales rs
    WHERE 
        rs.rank_within_item <= 5
    GROUP BY 
        rs.ws_item_sk
),
CustomerReturns AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returns,
        AVG(wr.wr_return_amt) AS avg_return_amount
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
)
SELECT 
    i.i_item_id,
    COALESCE(ts.total_sales, 0) AS total_sales,
    COALESCE(ts.total_profit, 0) AS total_profit,
    COALESCE(cr.total_returns, 0) AS total_returns,
    COALESCE(cr.avg_return_amount, 0.00) AS avg_return_amount,
    CASE 
        WHEN COALESCE(ts.total_profit, 0) > 0 THEN 'Profitable'
        ELSE 'Not Profitable'
    END AS profitability_status,
    CONCAT('Item ', i.i_item_id, 
           ' has ', COALESCE(ts.total_sales, 0), ' in sales, ', 
           COALESCE(ts.total_profit, 0), ' in profit, and ', 
           COALESCE(cr.total_returns, 0), ' returns.') AS summary_message
FROM 
    item i
LEFT JOIN 
    TopSales ts ON i.i_item_sk = ts.ws_item_sk
LEFT JOIN 
    CustomerReturns cr ON i.i_item_sk = cr.wr_item_sk
WHERE 
    i.i_current_price IS NOT NULL
    AND (SELECT COUNT(*) FROM inventory iv WHERE iv.inv_item_sk = i.i_item_sk AND iv.inv_quantity_on_hand IS NULL) = 0
ORDER BY 
    total_profit DESC, i.i_item_id ASC;
