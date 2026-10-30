
WITH  SalesCTE AS (
    SELECT ws_sold_date_sk, ws_item_sk, ws_sales_price, ws_quantity,
           ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
),
CustomerDetails AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender,
           COALESCE(hd.hd_buy_potential, 'Unknown') AS buy_potential,
           CASE 
               WHEN cd.cd_dep_count IS NULL THEN 'N/A'
               ELSE CAST(cd.cd_dep_count AS STRING) 
           END AS dep_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
SalesAggregation AS (
    SELECT ws_item_sk, SUM(ws_sales_price * ws_quantity) AS total_sales,
           COUNT(DISTINCT ws_bill_customer_sk) AS customer_count
    FROM web_sales
    GROUP BY ws_item_sk
),
TopSales AS (
    SELECT i.i_item_sk AS sales_item, s.total_sales, cd.c_first_name, cd.c_last_name, cd.buy_potential,
           RANK() OVER (ORDER BY s.total_sales DESC) AS sales_rank
    FROM SalesAggregation s
    JOIN item i ON s.ws_item_sk = i.i_item_sk
    JOIN CustomerDetails cd ON cd.c_customer_sk IN (SELECT DISTINCT ws_bill_customer_sk FROM web_sales WHERE ws_item_sk = s.ws_item_sk)
    WHERE i.i_current_price > 10.00 AND i.i_current_price IS NOT NULL
)

SELECT ts.sales_item, ts.total_sales, ts.c_first_name, ts.c_last_name, ts.buy_potential
FROM TopSales ts
WHERE ts.sales_rank <= 10
ORDER BY ts.total_sales DESC;
