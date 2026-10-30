
WITH ReturnedItems AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returned_qty,
        SUM(wr_return_amt_inc_tax) AS total_returned_amt
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
),
SalesStats AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sold_qty,
        SUM(ws_sales_price) AS total_sold_amt
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
Summary AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        COALESCE(ss.total_sold_qty, 0) AS sold_qty,
        COALESCE(ss.total_sold_amt, 0) AS sold_amt,
        COALESCE(ri.total_returned_qty, 0) AS returned_qty,
        COALESCE(ri.total_returned_amt, 0) AS returned_amt,
        (COALESCE(ss.total_sold_amt, 0) - COALESCE(ri.total_returned_amt, 0)) AS net_revenue
    FROM 
        item i
    LEFT JOIN 
        SalesStats ss ON i.i_item_sk = ss.ws_item_sk
    LEFT JOIN 
        ReturnedItems ri ON i.i_item_sk = ri.wr_item_sk
    WHERE 
        i.i_current_price > 20.00 AND 
        i.i_category = 'Electronics'
)
SELECT 
    s.i_item_id,
    s.i_item_desc,
    s.sold_qty,
    s.sold_amt,
    s.returned_qty,
    s.returned_amt,
    s.net_revenue
FROM 
    Summary s
WHERE 
    s.net_revenue > 0
ORDER BY 
    s.net_revenue DESC
LIMIT 100;
