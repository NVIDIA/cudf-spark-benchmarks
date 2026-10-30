
WITH RankedSales AS (
    SELECT 
        ws_ship_date_sk,
        ws_web_site_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid,
        DENSE_RANK() OVER (PARTITION BY ws_web_site_sk ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_ship_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND ws_ship_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_ship_date_sk, 
        ws_web_site_sk, 
        ws_item_sk
),
TopSales AS (
    SELECT 
        web_site_id,
        ws_item_sk,
        total_quantity,
        total_net_paid
    FROM 
        RankedSales r
    JOIN 
        web_site w ON r.ws_web_site_sk = w.web_site_sk
    WHERE 
        sales_rank <= 10
),
TotalReturns AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returned,
        SUM(wr_return_amt) AS total_return_amount
    FROM 
        web_returns
    WHERE 
        wr_returned_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        wr_item_sk
)
SELECT 
    t.web_site_id,
    i.i_item_id,
    t.total_quantity,
    t.total_net_paid,
    COALESCE(r.total_returned, 0) AS total_returned,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    (t.total_net_paid - COALESCE(r.total_return_amount, 0)) AS net_profit
FROM 
    TopSales t
JOIN 
    item i ON t.ws_item_sk = i.i_item_sk
LEFT JOIN 
    TotalReturns r ON t.ws_item_sk = r.wr_item_sk
ORDER BY 
    t.total_net_paid DESC;
