
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_quantity DESC) AS quantity_rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (
        SELECT d_date_sk 
        FROM date_dim 
        WHERE d_year = 2023
    )
),
SalesSummary AS (
    SELECT 
        item.i_item_sk,
        item.i_item_desc,
        SUM(sales.ws_sales_price * sales.ws_quantity) AS total_sales,
        COUNT(sales.ws_order_number) AS total_orders
    FROM RankedSales sales
    JOIN item ON sales.ws_item_sk = item.i_item_sk
    WHERE sales.price_rank = 1
    GROUP BY item.i_item_sk, item.i_item_desc
),
CustomerWithReturns AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        (SELECT COUNT(*) 
         FROM store_returns sr 
         WHERE sr.sr_customer_sk = c.c_customer_sk) AS returns_count,
        (SELECT SUM(sr.sr_return_amt) 
         FROM store_returns sr 
         WHERE sr.sr_customer_sk = c.c_customer_sk) AS total_returns_amt
    FROM customer c
)
SELECT 
    SUM(ss.total_sales) AS overall_sales,
    COUNT(DISTINCT cwr.c_customer_id) AS returning_customers,
    MAX(ss.total_orders) AS max_orders_per_item,
    AVG(COALESCE(cwr.total_returns_amt, 0)) AS avg_returns_per_customer
FROM SalesSummary ss
LEFT JOIN CustomerWithReturns cwr ON cwr.returns_count > 0
WHERE ss.total_sales > 1000
GROUP BY ss.i_item_sk, ss.i_item_desc
HAVING COUNT(ss.total_orders) > 5
ORDER BY overall_sales DESC
LIMIT 10;
