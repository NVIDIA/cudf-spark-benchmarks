
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk 
                                FROM date_dim 
                                WHERE d_year = 2023)
),
TopSales AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.ws_quantity) AS total_quantity,
        SUM(rs.ws_sales_price * rs.ws_quantity) AS total_sales
    FROM 
        RankedSales rs
    WHERE 
        rs.price_rank <= 5
    GROUP BY 
        rs.ws_item_sk
),
CustomerReturns AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returns,
        SUM(wr.wr_return_amt_inc_tax) AS return_amount
    FROM 
        web_returns wr
    WHERE 
        wr.wr_returned_date_sk IN (SELECT d_date_sk 
                                    FROM date_dim 
                                    WHERE d_year = 2023)
    GROUP BY 
        wr.wr_item_sk
)
SELECT 
    ts.ws_item_sk,
    ts.total_quantity,
    ts.total_sales,
    COALESCE(cr.total_returns, 0) AS total_returns,
    COALESCE(cr.return_amount, 0) AS return_amount,
    (ts.total_sales - COALESCE(cr.return_amount, 0)) AS net_sales
FROM 
    TopSales ts
LEFT JOIN 
    CustomerReturns cr ON ts.ws_item_sk = cr.wr_item_sk
ORDER BY 
    net_sales DESC
LIMIT 10;
