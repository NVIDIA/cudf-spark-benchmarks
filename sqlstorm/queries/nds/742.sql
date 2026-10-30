
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_paid DESC) AS rnk
    FROM 
        web_sales AS ws
    WHERE
        ws.ws_ship_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND ws.ws_ship_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
CustomerReturns AS (
    SELECT 
        wr.wr_item_sk,
        COUNT(wr.wr_return_quantity) AS total_returns,
        SUM(wr.wr_return_amt) AS total_returned_amt
    FROM 
        web_returns AS wr
    GROUP BY 
        wr.wr_item_sk
)
SELECT 
    i.i_item_id,
    i.i_product_name,
    COALESCE(RS.total_sales, 0) AS total_sales,
    COALESCE(RS.total_quantity, 0) AS total_quantity,
    COALESCE(CR.total_returns, 0) AS total_returns,
    COALESCE(CR.total_returned_amt, 0) AS total_returned_amt,
    (COALESCE(RS.total_sales, 0) - COALESCE(CR.total_returned_amt, 0)) AS net_revenue,
    CASE
        WHEN RS.total_sales IS NOT NULL AND CR.total_returns IS NOT NULL THEN (COALESCE(RS.total_sales, 0) / NULLIF(CR.total_returns, 0))
        ELSE NULL
    END AS revenue_per_return
FROM 
    item AS i
LEFT JOIN (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_net_paid) AS total_sales,
        SUM(ws.ws_quantity) AS total_quantity
    FROM 
        web_sales AS ws
    GROUP BY 
        ws.ws_item_sk
) AS RS ON i.i_item_sk = RS.ws_item_sk
LEFT JOIN CustomerReturns AS CR ON i.i_item_sk = CR.wr_item_sk
WHERE 
    EXISTS (
        SELECT 1 
        FROM RankedSales r 
        WHERE r.ws_item_sk = i.i_item_sk AND r.rnk = 1
    )
ORDER BY 
    net_revenue DESC,
    total_returns DESC
LIMIT 50;
