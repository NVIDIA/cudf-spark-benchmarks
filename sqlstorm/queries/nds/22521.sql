
WITH RankedSales AS (
    SELECT ws_item_sk, 
           SUM(ws_sales_price) AS total_sales, 
           RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 1 AND 1000
    GROUP BY ws_item_sk
),
CustomerSummary AS (
    SELECT c.c_customer_sk,
           COUNT(DISTINCT ws_order_number) AS total_orders,
           COUNT(DISTINCT CASE WHEN cd_marital_status = 'M' THEN c.c_customer_sk END) AS married_customers
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY c.c_customer_sk
),
ItemReturns AS (
    SELECT sr_item_sk,
           SUM(sr_return_quantity) AS total_returns
    FROM store_returns
    GROUP BY sr_item_sk
),
FinalSales AS (
    SELECT rs.ws_item_sk,
           COALESCE(rs.total_sales, 0) AS total_sales,
           COALESCE(ir.total_returns, 0) AS total_returns,
           cs.total_orders,
           cs.married_customers
    FROM RankedSales rs
    LEFT JOIN ItemReturns ir ON rs.ws_item_sk = ir.sr_item_sk
    LEFT JOIN CustomerSummary cs ON cs.c_customer_sk = (
        SELECT c.c_customer_sk
        FROM customer c
        ORDER BY c.c_birth_year DESC, c.c_birth_month DESC, c.c_birth_day DESC
        LIMIT 1
    )
    WHERE rs.sales_rank = 1
)
SELECT fs.ws_item_sk,
       fs.total_sales,
       fs.total_returns,
       CASE WHEN fs.total_sales > 0 THEN 'Profitable' ELSE 'Unprofitable' END AS profitability,
       CASE 
           WHEN fs.total_returns IS NULL THEN 'No Returns'
           WHEN fs.total_returns > 10 THEN 'High Returns'
           WHEN fs.total_returns BETWEEN 1 AND 10 THEN 'Low Returns'
           ELSE 'Invalid Returns'
       END AS returns_category,
       CONCAT('Sales for item ', fs.ws_item_sk, ' amount to ', CAST(fs.total_sales AS CHAR(100)), ' with ', fs.total_returns, ' returned items.') AS sales_summary
FROM FinalSales fs
WHERE fs.total_orders > 0 
  AND fs.married_customers IS NOT NULL
ORDER BY fs.total_sales DESC, fs.total_returns ASC;
