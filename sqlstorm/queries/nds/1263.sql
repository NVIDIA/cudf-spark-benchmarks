
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) - 30 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ws_item_sk
),
CustomerReturns AS (
    SELECT 
        wr_item_sk,
        COUNT(wr_return_quantity) AS total_returns,
        SUM(wr_return_amt) AS total_return_amount
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
),
TopItems AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_quantity_sold,
        rs.total_sales,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        CASE 
            WHEN rs.total_sales > 5000 THEN 'High Value'
            WHEN rs.total_sales BETWEEN 1000 AND 5000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS sales_category
    FROM 
        RankedSales rs
    LEFT JOIN 
        CustomerReturns cr ON rs.ws_item_sk = cr.wr_item_sk
    WHERE 
        rs.sales_rank <= 10
)
SELECT 
    ti.ws_item_sk,
    ti.total_quantity_sold,
    ti.total_sales,
    ti.total_returns,
    ti.total_return_amount,
    ti.sales_category,
    ROUND(1.0 * ti.total_returns / NULLIF(ti.total_quantity_sold, 0), 4) AS return_rate,
    CASE 
        WHEN ROUND(1.0 * ti.total_returns / NULLIF(ti.total_quantity_sold, 0), 4) > 0.1 THEN 'High Return Rate'
        ELSE 'Acceptable Return Rate'
    END AS return_rate_category
FROM 
    TopItems ti
ORDER BY 
    ti.total_sales DESC;
