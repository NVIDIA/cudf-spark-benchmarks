
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
),
TopSales AS (
    SELECT 
        rs.ws_item_sk, 
        rs.total_sales,
        i.i_item_desc,
        i.i_current_price
    FROM 
        RankedSales rs
    JOIN 
        item i ON rs.ws_item_sk = i.i_item_sk
    WHERE 
        rs.sales_rank <= 10
),
ReturnStats AS (
    SELECT 
        wr_item_sk,
        COUNT(DISTINCT wr_order_number) AS total_returns,
        SUM(wr_return_amt_inc_tax) AS total_return_value
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
),
FinalReport AS (
    SELECT 
        ts.ws_item_sk,
        ts.i_item_desc,
        ts.i_current_price,
        ts.total_sales,
        COALESCE(rs.total_returns, 0) AS total_returns,
        COALESCE(rs.total_return_value, 0) AS total_return_value,
        (ts.total_sales - COALESCE(rs.total_return_value, 0)) AS net_sales
    FROM 
        TopSales ts
    LEFT JOIN 
        ReturnStats rs ON ts.ws_item_sk = rs.wr_item_sk
)

SELECT 
    f.ws_item_sk,
    f.i_item_desc,
    f.i_current_price,
    f.total_sales,
    f.total_returns,
    f.total_return_value,
    f.net_sales
FROM 
    FinalReport f
WHERE 
    f.net_sales > 0
ORDER BY 
    f.net_sales DESC;
