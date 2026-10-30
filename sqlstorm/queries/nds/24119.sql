
WITH SalesData AS (
    SELECT 
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_item_sk ORDER BY SUM(cs.cs_net_profit) DESC) AS rn
    FROM 
        catalog_sales cs
    JOIN 
        date_dim dd ON cs.cs_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
        AND dd.d_month_seq BETWEEN 1 AND 6
    GROUP BY 
        cs.cs_item_sk
),
FilteredSales AS (
    SELECT 
        sd.cs_item_sk,
        sd.total_sales,
        sd.total_profit,
        CASE 
            WHEN sd.total_sales > 1000 THEN 'High'
            WHEN sd.total_sales BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS sales_category
    FROM 
        SalesData sd
    WHERE 
        sd.rn = 1
),
CustomerReturns AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returns,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_orders
    FROM 
        catalog_returns cr
    JOIN 
        SalesData sd ON cr.cr_item_sk = sd.cs_item_sk
    GROUP BY 
        cr.cr_item_sk
)
SELECT 
    fs.cs_item_sk,
    fs.total_sales,
    fs.total_profit,
    fs.sales_category,
    COALESCE(cr.total_returns, 0) AS total_returns,
    CASE 
        WHEN cr.total_returns IS NULL THEN 'No Returns'
        WHEN cr.total_returns >= 5 THEN 'Excessive Returns'
        ELSE 'Normal Returns'
    END AS return_category
FROM 
    FilteredSales fs
LEFT JOIN 
    CustomerReturns cr ON fs.cs_item_sk = cr.cr_item_sk
WHERE 
    fs.total_sales > (SELECT AVG(total_sales) FROM FilteredSales)
ORDER BY 
    fs.total_profit DESC
LIMIT 10;
