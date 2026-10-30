
WITH
  sales_summary AS (
    SELECT
      i.i_item_id,
      i.i_category,
      SUM(ss.ss_quantity) AS total_quantity_sold,
      SUM(ss.ss_sales_price) AS total_sales_amount,
      COUNT(DISTINCT ss.ss_customer_sk) AS unique_customers
    FROM
      item i
    JOIN
      store_sales ss ON i.i_item_sk = ss.ss_item_sk
    WHERE
      ss.ss_sold_date_sk BETWEEN 2459345 AND 2459499  
    GROUP BY
      i.i_item_id, i.i_category
  ),
  customer_summary AS (
    SELECT
      c.c_customer_id,
      cd.cd_gender,
      SUM(ss.ss_sales_price) AS total_spent
    FROM
      customer c
    JOIN
      customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
      store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE
      ss.ss_sold_date_sk BETWEEN 2459345 AND 2459499  
    GROUP BY
      c.c_customer_id, cd.cd_gender
  ),
  overall_summary AS (
    SELECT
      ss.total_quantity_sold,
      ss.total_sales_amount,
      cs.total_spent,
      cs.cd_gender
    FROM
      sales_summary ss
    JOIN
      customer_summary cs ON ss.unique_customers > 100  
  )
SELECT
  OS.total_quantity_sold,
  OS.total_sales_amount,
  OS.total_spent,
  OS.cd_gender
FROM
  overall_summary OS
ORDER BY
  OS.total_sales_amount DESC
LIMIT 10;
