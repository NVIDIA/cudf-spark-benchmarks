
WITH CTE_Sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (
            SELECT d.d_date_sk FROM date_dim d WHERE d.d_date = '2023-01-01'
        ) AND (
            SELECT d.d_date_sk FROM date_dim d WHERE d.d_date = '2023-12-31'
        )
    GROUP BY 
        ws.ws_item_sk
),
CTE_Returns AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returned,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amount
    FROM 
        web_returns wr
    WHERE 
        wr.wr_returned_date_sk BETWEEN (
            SELECT d.d_date_sk FROM date_dim d WHERE d.d_date = '2023-01-01'
        ) AND (
            SELECT d.d_date_sk FROM date_dim d WHERE d.d_date = '2023-12-31'
        )
    GROUP BY 
        wr.wr_item_sk
),
CTE_Combined AS (
    SELECT 
        s.i_item_sk,
        COALESCE(cs.total_quantity, 0) AS web_sales_qty,
        COALESCE(cs.total_sales, 0) AS web_sales_amt,
        COALESCE(cr.total_returned, 0) AS returned_qty,
        COALESCE(cr.total_return_amount, 0) AS return_amt
    FROM 
        item s
    LEFT JOIN 
        CTE_Sales cs ON s.i_item_sk = cs.ws_item_sk
    LEFT JOIN 
        CTE_Returns cr ON s.i_item_sk = cr.wr_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    c.web_sales_qty,
    c.web_sales_amt,
    c.returned_qty,
    c.return_amt,
    (c.web_sales_amt - c.return_amt) AS net_sales,
    RANK() OVER (ORDER BY (c.web_sales_amt - c.return_amt) DESC) AS sales_rank
FROM 
    CTE_Combined c
JOIN 
    item i ON c.i_item_sk = i.i_item_sk
WHERE 
    (c.web_sales_amt - c.return_amt) > 0
ORDER BY 
    net_sales DESC
LIMIT 10;
