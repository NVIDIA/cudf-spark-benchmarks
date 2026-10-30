
WITH non_returned_sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2450000 AND 2450500
    GROUP BY 
        ws.ws_item_sk
),
returned_sales AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returned_quantity,
        SUM(wr.wr_return_amt) AS total_returned_amnt
    FROM 
        web_returns wr
    WHERE 
        wr.wr_returned_date_sk BETWEEN 2450000 AND 2450500
    GROUP BY 
        wr.wr_item_sk
),
item_summary AS (
    SELECT 
        i.i_item_id,
        COALESCE(n.total_quantity, 0) AS total_quantity_sold,
        COALESCE(n.total_sales, 0) AS total_sales_value,
        COALESCE(r.total_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(r.total_returned_amnt, 0) AS total_returned_amount,
        (COALESCE(n.total_sales, 0) - COALESCE(r.total_returned_amnt, 0)) AS net_income,
        CASE 
            WHEN COALESCE(n.total_quantity, 0) = 0 THEN 'No Sales'
            ELSE 'Sold'
        END AS sales_status
    FROM 
        item i
    LEFT JOIN 
        non_returned_sales n ON i.i_item_sk = n.ws_item_sk
    LEFT JOIN 
        returned_sales r ON i.i_item_sk = r.wr_item_sk
)
SELECT 
    isum.i_item_id,
    isum.total_quantity_sold,
    isum.total_sales_value,
    isum.total_returned_quantity,
    isum.total_returned_amount,
    isum.net_income,
    isum.sales_status
FROM 
    item_summary isum
WHERE 
    isum.net_income > 1000
ORDER BY 
    isum.net_income DESC;
