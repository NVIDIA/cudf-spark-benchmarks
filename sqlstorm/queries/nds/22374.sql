
WITH  ShipModes AS (
    SELECT sm_ship_mode_sk, sm_type, sm_carrier, 
           CASE 
               WHEN sm_type LIKE '%Express%' THEN 1 
               WHEN sm_type LIKE '%Standard%' THEN 2 
               ELSE 3 
           END AS priority
    FROM ship_mode
), CustomerStats AS (
    SELECT c.c_customer_sk, 
           COUNT(sr_item_sk) AS total_returns,
           SUM(COALESCE(sr_return_amt, 0)) AS total_return_amount,
           COUNT(DISTINCT cs_order_number) AS total_orders,
           COUNT(DISTINCT wr_order_number) AS web_total_orders,
           ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(COALESCE(sr_return_amt, 0)) DESC) AS rn
    FROM customer c
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY c.c_customer_sk
), AggregateSales AS (
    SELECT ws_bill_customer_sk, 
           SUM(ws_net_paid) AS total_sales, 
           SUM(ws_ext_discount_amt) AS total_discount,
           AVG(ws_net_profit) AS avg_net_profit,
           NTILE(4) OVER (ORDER BY SUM(ws_net_paid) DESC) AS sales_quartile
    FROM web_sales
    GROUP BY ws_bill_customer_sk
), FilteredSales AS (
    SELECT cs.c_customer_sk, 
           cs.total_returns,
           cs.total_return_amount,
           asales.total_sales,
           asales.total_discount,
           asales.avg_net_profit,
           asales.sales_quartile
    FROM CustomerStats cs
    JOIN AggregateSales asales ON cs.c_customer_sk = asales.ws_bill_customer_sk
    WHERE cs.total_returns > 0 AND asales.total_sales > 100
)
SELECT fs.c_customer_sk,
       CONCAT('Customer SK: ', fs.c_customer_sk, ' - Total Returns: ', fs.total_returns, 
              ' - Total Return Amount: $', fs.total_return_amount, 
              ' - Total Sales: $', fs.total_sales,
              ' - Avg Net Profit: $', fs.avg_net_profit) AS customer_summary,
       sm.sm_type AS shipping_method
FROM FilteredSales fs
LEFT JOIN ShipModes sm ON fs.sales_quartile = sm.priority
WHERE sm.sm_carrier IS NOT NULL
ORDER BY fs.total_return_amount DESC, fs.total_sales ASC
LIMIT 50 OFFSET 5;
