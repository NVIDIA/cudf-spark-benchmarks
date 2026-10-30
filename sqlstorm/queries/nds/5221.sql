
WITH 
  sales_data AS (
    SELECT 
      ws_sold_date_sk,
      SUM(ws_quantity) AS total_quantity,
      SUM(ws_net_paid) AS total_sales,
      ws_item_sk
    FROM 
      web_sales
    GROUP BY 
      ws_sold_date_sk, ws_item_sk
  ),
  customer_data AS (
    SELECT 
      c.c_customer_sk,
      c.c_first_name,
      c.c_last_name,
      cd.cd_gender,
      cd.cd_marital_status
    FROM 
      customer c
    JOIN 
      customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
  ),
  sales_summary AS (
    SELECT 
      sd.ws_sold_date_sk,
      SUM(sd.total_quantity) AS total_quantity_sold,
      SUM(sd.total_sales) AS total_sales_value,
      COUNT(DISTINCT cd.c_customer_sk) AS unique_customers,
      MAX(sd.total_sales) AS max_sales_per_item,
      MIN(sd.total_sales) AS min_sales_per_item
    FROM 
      sales_data sd
    JOIN 
      customer_data cd ON cd.c_customer_sk IN (
        SELECT DISTINCT 
          ws_bill_customer_sk 
        FROM 
          web_sales 
        WHERE 
          ws_sold_date_sk = sd.ws_sold_date_sk
      )
    GROUP BY 
      sd.ws_sold_date_sk
  )
SELECT 
  dd.d_date AS sales_date,
  ss.total_quantity_sold,
  ss.total_sales_value,
  ss.unique_customers,
  ss.max_sales_per_item,
  ss.min_sales_per_item
FROM 
  sales_summary ss
JOIN 
  date_dim dd ON ss.ws_sold_date_sk = dd.d_date_sk
WHERE 
  dd.d_year = 2023 
  AND dd.d_month_seq IN (1, 2, 3)
ORDER BY 
  dd.d_date;
