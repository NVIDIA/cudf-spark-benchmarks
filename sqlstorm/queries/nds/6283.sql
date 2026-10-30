
WITH RankedReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_return_time_sk,
        sr_item_sk,
        sr_customer_sk,
        sr_return_quantity,
        sr_return_amt_inc_tax,
        sr_store_sk,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY sr_returned_date_sk DESC) as rn
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim WHERE d_year = 2023)
),
SalesSummary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sold,
        SUM(ws_net_paid) AS total_revenue,
        SUM(ws_ext_discount_amt) AS total_discount
    FROM 
        web_sales
    WHERE 
        ws_ship_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
),
TopItems AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        COALESCE(rs.total_sold, 0) AS total_sold,
        COALESCE(rs.total_revenue, 0) AS total_revenue,
        COALESCE(rs.total_discount, 0) AS total_discount,
        COALESCE(rr.total_return_qty, 0) AS total_return_qty,
        COALESCE(rr.total_return_amt, 0) AS total_return_amt
    FROM 
        item i
    LEFT JOIN SalesSummary rs ON i.i_item_sk = rs.ws_item_sk
    LEFT JOIN (
        SELECT 
            sr_item_sk,
            SUM(sr_return_quantity) AS total_return_qty,
            SUM(sr_return_amt_inc_tax) AS total_return_amt
        FROM 
            RankedReturns
        GROUP BY 
            sr_item_sk
    ) rr ON i.i_item_sk = rr.sr_item_sk
)
SELECT 
    ti.i_item_sk,
    ti.i_item_desc,
    ti.total_sold,
    ti.total_revenue,
    ti.total_discount,
    ti.total_return_qty,
    ti.total_return_amt
FROM 
    TopItems ti
ORDER BY 
    ti.total_revenue DESC
LIMIT 10;
