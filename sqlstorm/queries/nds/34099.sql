
WITH  cte_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price * ws_quantity) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price * ws_quantity) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk

    UNION ALL

    SELECT 
        cs_item_sk,
        SUM(cs_sales_price * cs_quantity) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY cs_item_sk ORDER BY SUM(cs_sales_price * cs_quantity) DESC) AS sales_rank
    FROM 
        catalog_sales
    GROUP BY 
        cs_item_sk
), 
cte_max_sales AS (
    SELECT 
        ws_item_sk,
        total_sales 
    FROM 
        cte_sales
    WHERE 
        sales_rank = 1
),
cte_returned_sales AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_amt) AS total_return_amt
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
),
combined AS (
    SELECT 
        cs.ws_item_sk AS s_item_sk,
        cs.total_sales, 
        COALESCE(rs.total_return_amt, 0) AS total_return_amt,
        cs.total_sales - COALESCE(rs.total_return_amt, 0) AS net_sales
    FROM 
        cte_max_sales cs
    LEFT JOIN 
        cte_returned_sales rs 
    ON 
        cs.ws_item_sk = rs.wr_item_sk
)
SELECT 
    i.i_item_id,
    COALESCE(c.total_sales, 0) AS total_sales,
    COALESCE(c.total_return_amt, 0) AS total_return_amt,
    c.net_sales
FROM 
    item i
LEFT JOIN 
    combined c 
ON 
    i.i_item_sk = c.s_item_sk
WHERE 
    i.i_current_price > 0 
    AND i.i_current_price < 100 
    AND NOT EXISTS (
        SELECT 1
        FROM inventory inv
        WHERE 
            inv.inv_item_sk = i.i_item_sk
            AND inv.inv_quantity_on_hand = 0
    )
ORDER BY 
    net_sales DESC
LIMIT 10;
