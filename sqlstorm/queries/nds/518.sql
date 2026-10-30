
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_sales_price, 
        ws.ws_quantity,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS sales_rank,
        SUM(ws.ws_quantity) OVER (PARTITION BY ws.ws_item_sk) AS total_sold
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d.d_date_sk 
                                FROM date_dim d 
                                WHERE d.d_year = 2023 AND d.d_month_seq BETWEEN 1 AND 6)
),
CustomerReturns AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returns,
        SUM(wr.wr_return_amt) AS total_return_amt
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
),
SalesOverview AS (
    SELECT 
        rs.ws_item_sk,
        rs.ws_sales_price,
        rs.total_sold,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_amt, 0) AS total_return_amt,
        CASE 
            WHEN COALESCE(cr.total_returns, 0) > 0 THEN 
                (COALESCE(cr.total_return_amt, 0) / NULLIF(rs.total_sold, 0)) * 100
            ELSE 
                0 
        END AS return_percentage
    FROM 
        RankedSales rs
    LEFT JOIN 
        CustomerReturns cr ON rs.ws_item_sk = cr.wr_item_sk
)
SELECT 
    so.ws_item_sk,
    i.i_item_desc,
    so.ws_sales_price,
    so.total_sold,
    so.total_returns,
    so.total_return_amt,
    so.return_percentage
FROM 
    SalesOverview so
JOIN 
    item i ON so.ws_item_sk = i.i_item_sk
WHERE 
    so.return_percentage > 10
ORDER BY 
    so.return_percentage DESC, 
    so.total_sold DESC;
