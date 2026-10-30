
WITH RankedSales AS (
  SELECT 
    ws.ws_item_sk,
    SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price * ws.ws_quantity) DESC) AS sales_rank
  FROM 
    web_sales ws
  JOIN 
    date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
  WHERE 
    dd.d_year = 2023 AND dd.d_month_seq IN (1, 2, 3)
  GROUP BY 
    ws.ws_item_sk
),
TopItems AS (
  SELECT 
    rs.ws_item_sk,
    rs.total_sales,
    rs.order_count,
    i.i_item_desc,
    i.i_current_price,
    i.i_brand
  FROM 
    RankedSales rs
  JOIN 
    item i ON rs.ws_item_sk = i.i_item_sk
  WHERE 
    rs.sales_rank <= 10
)
SELECT 
  ti.i_item_desc,
  ti.total_sales,
  ti.order_count,
  ti.i_current_price,
  ti.i_brand,
  ca.ca_city,
  COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers
FROM 
  TopItems ti
JOIN 
  web_sales ws ON ti.ws_item_sk = ws.ws_item_sk
JOIN 
  customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN 
  customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
GROUP BY 
  ti.i_item_desc, ti.total_sales, ti.order_count, ti.i_current_price, ti.i_brand, ca.ca_city
ORDER BY 
  ti.total_sales DESC;
