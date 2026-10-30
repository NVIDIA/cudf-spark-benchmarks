
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) AS sales_rank
    FROM 
        web_sales ws
),
TotalReturns AS (
    SELECT 
        sr_item_sk, 
        SUM(sr_return_quantity) AS total_return_qty,
        SUM(sr_return_amt_inc_tax) AS total_return_amt
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
ItemInfo AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        COALESCE(tr.total_return_qty, 0) AS total_return_qty,
        COALESCE(tr.total_return_amt, 0) AS total_return_amount
    FROM 
        item i
    LEFT JOIN 
        TotalReturns tr ON i.i_item_sk = tr.sr_item_sk
)
SELECT 
    ci.c_customer_id,
    ci.c_first_name,
    ci.c_last_name,
    ii.i_item_desc,
    SUM(rs.ws_quantity) AS total_quantity_sold,
    SUM(rs.ws_sales_price * rs.ws_quantity) AS total_sales_value,
    AVG(ii.i_current_price) AS avg_item_price,
    SUM(ii.total_return_qty) AS total_returns,
    MAX(ii.total_return_amount) AS max_return_amount
FROM 
    customer ci
JOIN 
    web_sales ws ON ci.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    RankedSales rs ON ws.ws_order_number = rs.ws_order_number
JOIN 
    ItemInfo ii ON rs.ws_item_sk = ii.i_item_sk
WHERE 
    ci.c_birth_year BETWEEN 1980 AND 1990
    AND ii.i_current_price > 20.00
GROUP BY 
    ci.c_customer_id, ci.c_first_name, ci.c_last_name, ii.i_item_desc
HAVING 
    SUM(rs.ws_quantity) > 10
ORDER BY 
    total_sales_value DESC
LIMIT 10;
