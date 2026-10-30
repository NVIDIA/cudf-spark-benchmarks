
WITH SalesSummary AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM
        web_sales
    WHERE
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY
        ws_item_sk
), 
TopSales AS (
    SELECT
        ss.ws_item_sk,
        ss.total_quantity,
        ss.total_sales,
        ss.order_count,
        ia.i_item_desc,
        ia.i_current_price,
        ia.i_brand
    FROM
        SalesSummary ss
    JOIN item ia ON ss.ws_item_sk = ia.i_item_sk
    WHERE 
        ss.sales_rank <= 10
),
CustomerReturns AS (
    SELECT
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt) AS total_returned_value
    FROM
        store_returns
    WHERE
        sr_returned_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY
        sr_item_sk
)
SELECT
    ts.ws_item_sk,
    ts.total_quantity,
    ts.total_sales,
    ts.order_count,
    COALESCE(cr.total_returns, 0) AS total_returns,
    COALESCE(cr.total_returned_value, 0) AS total_returned_value,
    COALESCE((ts.total_sales - cr.total_returned_value), ts.total_sales) AS net_sales,
    CONCAT(CAST((COALESCE(cr.total_returned_value, 0) / NULLIF(ts.total_sales, 0) * 100) AS DECIMAL(5, 2)), '%') AS return_percentage,
    CASE 
        WHEN ts.total_sales > 10000 THEN 'High Performer' 
        WHEN ts.total_sales BETWEEN 5000 AND 10000 THEN 'Medium Performer'
        ELSE 'Low Performer' 
    END AS performance_category
FROM
    TopSales ts
LEFT JOIN
    CustomerReturns cr ON ts.ws_item_sk = cr.sr_item_sk
ORDER BY
    ts.total_sales DESC;
