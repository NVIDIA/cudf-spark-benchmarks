WITH SalesData AS (
    SELECT
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2450010 AND 2450600 
    GROUP BY ws_item_sk
),
CustomerReturns AS (
    SELECT
        wr_item_sk,
        SUM(wr_return_amt) AS total_return_amount,
        COUNT(DISTINCT wr_order_number) AS total_returns
    FROM web_returns
    GROUP BY wr_item_sk
),
CombinedSales AS (
    SELECT
        sd.ws_item_sk,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        COALESCE(sd.total_orders, 0) AS total_orders,
        COALESCE(cr.total_returns, 0) AS total_returns,
        (COALESCE(sd.total_sales, 0) - COALESCE(cr.total_return_amount, 0)) AS net_sales
    FROM SalesData sd
    FULL OUTER JOIN CustomerReturns cr ON sd.ws_item_sk = cr.wr_item_sk
),
RankedSales AS (
    SELECT
        cs.*,
        RANK() OVER (ORDER BY net_sales DESC) AS rank
    FROM CombinedSales cs
)
SELECT 
    CASE 
        WHEN rank <= 10 THEN 'Top 10 Items'
        WHEN rank <= 20 THEN 'Next 10 Items'
        ELSE 'Other Items'
    END AS sales_category,
    COUNT(*) AS item_count,
    SUM(total_sales) AS category_total_sales,
    SUM(total_return_amount) AS category_total_returns,
    SUM(net_sales) AS category_net_sales
FROM RankedSales
GROUP BY sales_category
ORDER BY sales_category;