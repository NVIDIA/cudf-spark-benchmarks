
WITH  SalesAggregate AS (
    SELECT ws_item_sk,
           SUM(ws_ext_sales_price) AS total_sales,
           COUNT(DISTINCT ws_order_number) AS order_count,
           MIN(ws_sold_date_sk) AS first_sale_date,
           MAX(ws_sold_date_sk) AS last_sale_date,
           ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_item_sk
),
TopSellingItems AS (
    SELECT sa.ws_item_sk,
           i.i_product_name,
           sa.total_sales,
           sa.order_count,
           sa.first_sale_date,
           sa.last_sale_date,
           DENSE_RANK() OVER (ORDER BY sa.total_sales DESC) AS rank
    FROM SalesAggregate sa
    JOIN item i ON sa.ws_item_sk = i.i_item_sk
    WHERE sa.sales_rank <= 10
),
CustomerDemographics AS (
    SELECT cd.cd_demo_sk,
           hd.hd_income_band_sk AS income_band,
           SUM(ws_ext_sales_price) AS total_purchases
    FROM web_sales
    JOIN customer c ON web_sales.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    GROUP BY cd.cd_demo_sk, hd.hd_income_band_sk
    HAVING SUM(ws_ext_sales_price) > 1000
)
SELECT tsi.i_product_name,
       tsi.total_sales,
       cd.income_band,
       cd.total_purchases
FROM TopSellingItems tsi
LEFT JOIN CustomerDemographics cd ON tsi.ws_item_sk = cd.cd_demo_sk
WHERE tsi.total_sales > (SELECT AVG(total_sales) FROM TopSellingItems)
ORDER BY tsi.total_sales DESC;
