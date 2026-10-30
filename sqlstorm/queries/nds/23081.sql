
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS rank_price,
        SUM(ws_sales_price) OVER (PARTITION BY ws_item_sk) AS total_sales_per_item
    FROM 
        web_sales
    WHERE 
        ws_sales_price > 0
),
FilteredSales AS (
    SELECT 
        rs.ws_item_sk,
        rs.ws_order_number,
        rs.ws_sales_price,
        CASE 
            WHEN rs.rank_price = 1 AND rs.total_sales_per_item > 1000 THEN 'Top Sale'
            WHEN rs.rank_price > 1 THEN 'Regular Sale'
            ELSE 'Low Sale'
        END AS sale_category
    FROM 
        RankedSales rs
),
AggregatedReturns AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returns,
        SUM(wr_return_amt) AS total_return_amount
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
),
SalesWithReturns AS (
    SELECT 
        fs.ws_item_sk,
        fs.ws_order_number,
        fs.ws_sales_price,
        fs.sale_category,
        COALESCE(ar.total_returns, 0) AS total_returns,
        COALESCE(ar.total_return_amount, 0) AS total_return_amount
    FROM 
        FilteredSales fs
    LEFT JOIN 
        AggregatedReturns ar ON fs.ws_item_sk = ar.wr_item_sk
)
SELECT 
    sow.ws_item_sk,
    CASE 
        WHEN sow.sale_category = 'Top Sale' AND sow.total_returns > 0 THEN 
            'Top Sale with Returns'
        WHEN sow.sale_category IN ('Regular Sale', 'Low Sale') AND sow.total_returns = 0 THEN 
            'Sales without Returns'
        ELSE 
            'Other'
    END AS sale_status,
    COUNT(*) AS total_orders,
    SUM(sow.ws_sales_price) AS total_sales_value,
    AVG(sow.ws_sales_price) AS avg_sales_price,
    MAX(sow.total_returns) AS max_returns
FROM 
    SalesWithReturns sow
WHERE 
    sow.ws_sales_price IS NOT NULL AND sow.ws_sales_price > 50
GROUP BY 
    sow.ws_item_sk, sale_status
HAVING 
    COUNT(*) > 5 OR SUM(sow.total_returns) > 3
ORDER BY 
    total_sales_value DESC, avg_sales_price ASC;
