
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_paid,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_paid DESC) AS rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
),
TotalReturns AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returned_qty,
        SUM(wr.wr_return_amt_inc_tax) AS total_returned_amt
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
),
AddressCount AS (
    SELECT 
        ca.ca_address_sk,
        COUNT(c.c_customer_sk) AS customer_count
    FROM 
        customer c
        JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca.ca_address_sk
)
SELECT 
    i.i_item_id,
    COALESCE(rs.total_quantity, 0) AS total_sales_quantity,
    COALESCE(rs.total_net_paid, 0) AS total_sales_revenue,
    COALESCE(tr.total_returned_qty, 0) AS total_returned_quantity,
    COALESCE(tr.total_returned_amt, 0) AS total_returned_amount,
    ac.customer_count
FROM 
    item i
LEFT JOIN (
    SELECT 
        rs.ws_item_sk, 
        SUM(rs.ws_quantity) AS total_quantity,
        SUM(rs.ws_net_paid) AS total_net_paid
    FROM 
        web_sales rs
    JOIN RankedSales r ON rs.ws_item_sk = r.ws_item_sk AND r.rank = 1
    GROUP BY 
        rs.ws_item_sk
) AS rs ON i.i_item_sk = rs.ws_item_sk
LEFT JOIN TotalReturns tr ON i.i_item_sk = tr.wr_item_sk
LEFT JOIN AddressCount ac ON i.i_item_sk = ac.ca_address_sk
WHERE 
    (tr.total_returned_amt IS NULL OR tr.total_returned_amt < 1000) 
    AND i.i_current_price > (
        SELECT AVG(i2.i_current_price) FROM item i2 WHERE i2.i_category_id = i.i_category_id
    )
ORDER BY 
    total_sales_revenue DESC
LIMIT 50;
