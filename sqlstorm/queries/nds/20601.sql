
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank,
        SUM(ws.ws_sales_price) OVER (PARTITION BY ws.ws_item_sk) AS total_sales_price
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d.d_date_sk) FROM date_dim d) - 30 AND (SELECT MAX(d.d_date_sk) FROM date_dim d)
),
TopSales AS (
    SELECT 
        rs.ws_item_sk,
        rs.ws_order_number,
        rs.ws_sales_price,
        CASE 
            WHEN rs.price_rank = 1 THEN 'Top Price'
            ELSE 'Other'
        END AS price_category
    FROM 
        RankedSales rs
    WHERE 
        rs.total_sales_price > (SELECT AVG(total) FROM (SELECT SUM(ws.ws_sales_price) AS total FROM web_sales ws GROUP BY ws.ws_item_sk) AS avg_table)
),
ReturnDetails AS (
    SELECT 
        wr.wr_item_sk,
        COUNT(wr.wr_return_quantity) AS total_returns,
        SUM(wr.wr_return_amt) AS total_return_amount
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
)
SELECT 
    ts.ws_item_sk,
    ts.price_category,
    COALESCE(rd.total_returns, 0) AS total_returns,
    COALESCE(rd.total_return_amount, 0) AS total_return_amount,
    CASE 
        WHEN COALESCE(rd.total_returns, 0) > 0 THEN 'Items Returned'
        ELSE 'No Returns'
    END AS return_status
FROM 
    TopSales ts
LEFT JOIN 
    ReturnDetails rd ON ts.ws_item_sk = rd.wr_item_sk
WHERE 
    ts.price_category = 'Top Price'
ORDER BY 
    ts.ws_item_sk;
