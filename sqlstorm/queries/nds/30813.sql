
WITH  SalesCTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) as rank
    FROM web_sales
    GROUP BY ws_item_sk
    HAVING SUM(ws_net_paid_inc_tax) > 100
),
RecentReturns AS (
    SELECT 
        wr_item_sk,
        COUNT(*) AS return_count,
        SUM(wr_return_amt) AS total_return_amt,
        ROW_NUMBER() OVER (PARTITION BY wr_item_sk ORDER BY COUNT(*) DESC) AS ranking
    FROM web_returns
    WHERE wr_returned_date_sk > (SELECT MAX(d_date_sk) - 30 FROM date_dim)
    GROUP BY wr_item_sk
),
SalesDetails AS (
    SELECT 
        i.i_item_id, 
        i.i_item_desc,
        coalesce(s.total_quantity, 0) AS total_quantity_sold,
        coalesce(s.total_sales, 0) AS total_sales,
        COALESCE(r.return_count, 0) AS total_returns,
        COALESCE(r.total_return_amt, 0) AS total_return_amount
    FROM item i
    LEFT JOIN SalesCTE s ON i.i_item_sk = s.ws_item_sk
    LEFT JOIN RecentReturns r ON i.i_item_sk = r.wr_item_sk
)

SELECT 
    sd.i_item_id,
    sd.i_item_desc,
    sd.total_quantity_sold,
    sd.total_sales,
    sd.total_returns,
    sd.total_return_amount,
    ROUND(sd.total_sales / NULLIF(sd.total_quantity_sold, 0), 2) AS avg_sale_per_item,
    CASE 
        WHEN sd.total_sales > 5000 THEN 'High Performer'
        WHEN sd.total_sales BETWEEN 1000 AND 5000 THEN 'Moderate Performer'
        ELSE 'Low Performer'
    END AS performance_category
FROM SalesDetails sd
WHERE sd.total_quantity_sold IS NOT NULL
ORDER BY sd.total_sales DESC
LIMIT 10;
