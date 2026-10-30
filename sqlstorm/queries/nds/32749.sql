
WITH RecursiveSales AS (
    SELECT 
        ws.ws_sales_price,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_order_number,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (
            SELECT d.d_date_sk 
            FROM date_dim d 
            WHERE d.d_year = 2023 AND d.d_month_seq BETWEEN 1 AND 6
        )
),
RankedReturns AS (
    SELECT 
        sr_return_amt,
        sr_item_sk,
        sr_return_quantity,
        sr_ticket_number,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY sr_return_amt DESC) AS return_rank
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk IN (
            SELECT d.d_date_sk 
            FROM date_dim d 
            WHERE d.d_year = 2023 AND d.d_week_seq IN (1, 2, 3)
        )
)
SELECT 
    i.i_item_desc,
    COALESCE(SUM(rs.ws_sales_price * rs.ws_quantity), 0) AS total_sales,
    COALESCE(SUM(rr.sr_return_amt * rr.sr_return_quantity), 0) AS total_returns,
    (COALESCE(SUM(rs.ws_sales_price * rs.ws_quantity), 0) - COALESCE(SUM(rr.sr_return_amt * rr.sr_return_quantity), 0)) AS net_sales,
    COUNT(DISTINCT rs.ws_order_number) AS order_count,
    COUNT(DISTINCT rr.sr_ticket_number) AS return_count
FROM 
    item i
LEFT JOIN 
    RecursiveSales rs ON i.i_item_sk = rs.ws_item_sk
LEFT JOIN 
    RankedReturns rr ON i.i_item_sk = rr.sr_item_sk AND rr.return_rank = 1
WHERE 
    i.i_current_price IS NOT NULL
GROUP BY 
    i.i_item_desc
HAVING 
    (COALESCE(SUM(rs.ws_sales_price * rs.ws_quantity), 0) - COALESCE(SUM(rr.sr_return_amt * rr.sr_return_quantity), 0)) > 1000
ORDER BY 
    net_sales DESC
LIMIT 10;
