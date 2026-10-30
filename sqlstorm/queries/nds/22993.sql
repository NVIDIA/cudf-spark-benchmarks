
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS rnk
    FROM web_sales
),
AggregateSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        AVG(ws_sales_price) AS average_sales_price,
        COUNT(*) AS sales_count
    FROM web_sales
    GROUP BY ws_item_sk
),
FilteredSales AS (
    SELECT 
        a.ws_item_sk,
        a.total_quantity,
        b.rnk,
        CASE 
            WHEN a.total_quantity > 100 THEN 'High Volume'
            WHEN a.total_quantity BETWEEN 50 AND 100 THEN 'Medium Volume'
            ELSE 'Low Volume'
        END AS volume_category
    FROM AggregateSales a
    LEFT JOIN RankedSales b ON a.ws_item_sk = b.ws_item_sk
    WHERE b.rnk = 1 OR b.rnk IS NULL
),
IncomeBands AS (
    SELECT
        hd_demo_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        CASE 
            WHEN ib.ib_lower_bound IS NULL OR ib.ib_upper_bound IS NULL THEN 'Undefined'
            ELSE CONCAT('Income range: ', ib.ib_lower_bound, ' - ', ib.ib_upper_bound)
        END AS income_description
    FROM household_demographics hd
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    fs.ws_item_sk,
    fs.total_quantity,
    fs.volume_category,
    ib.income_description,
    MAX(COALESCE(fs.total_quantity * a.average_sales_price, 0)) AS max_revenue
FROM FilteredSales fs
FULL OUTER JOIN IncomeBands ib ON fs.ws_item_sk = ib.hd_demo_sk
LEFT JOIN AggregateSales a ON fs.ws_item_sk = a.ws_item_sk
GROUP BY 
    fs.ws_item_sk, 
    fs.total_quantity,
    fs.volume_category, 
    ib.income_description
HAVING 
    MAX(COALESCE(fs.total_quantity, 0)) > 0
ORDER BY max_revenue DESC
LIMIT 10;
