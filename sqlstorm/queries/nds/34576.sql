
WITH  RecentReturns AS (
    SELECT sr_item_sk, SUM(sr_return_quantity) AS total_returned, COUNT(*) AS return_count
    FROM store_returns
    WHERE sr_returned_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY sr_item_sk
),
TopReturnedItems AS (
    SELECT rr.sr_item_sk, ii.i_item_desc, rr.total_returned, rr.return_count,
           ROW_NUMBER() OVER (ORDER BY rr.total_returned DESC) AS rank
    FROM RecentReturns rr
    JOIN item ii ON rr.sr_item_sk = ii.i_item_sk
    WHERE rr.total_returned > 0
),
RevenueStats AS (
    SELECT ws_ship_date_sk, SUM(ws_sales_price) AS total_sales,
           AVG(ws_sales_price) AS avg_sales_price,
           SUM(ws_sales_price) - SUM(ws_ext_discount_amt) AS net_revenue
    FROM web_sales
    GROUP BY ws_ship_date_sk
),
CustomerDemographics AS (
    SELECT cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status,
           COUNT(DISTINCT c.c_customer_id) AS customer_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
)
SELECT r.rank, r.i_item_desc, r.total_returned, 
       (CASE 
            WHEN r.return_count > 5 THEN 'High'
            WHEN r.return_count BETWEEN 3 AND 5 THEN 'Medium'
            ELSE 'Low'
       END) AS return_category,
       DATE(d.d_date) AS sales_date,
       rev.total_sales,
       cust.customer_count,
       (cust.customer_count * 1.0 / NULLIF(rev.total_sales, 0)) AS sales_per_customer
FROM TopReturnedItems r
LEFT JOIN RevenueStats rev ON r.rank <= 10
LEFT JOIN date_dim d ON d.d_date_sk = rev.ws_ship_date_sk
LEFT JOIN CustomerDemographics cust ON TRUE
WHERE r.total_returned > 0
ORDER BY r.total_returned DESC, sales_date;
