
WITH RankedSales AS (
  SELECT 
    ws.ws_item_sk,
    ws.ws_order_number,
    ws.ws_sales_price,
    RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank
  FROM 
    web_sales ws
  WHERE 
    ws.ws_sales_price IS NOT NULL
),
TotalReturns AS (
  SELECT 
    wr.wr_item_sk,
    SUM(wr.wr_return_quantity) AS total_returned_quantity,
    SUM(wr.wr_return_amt_inc_tax) AS total_returned_amount
  FROM 
    web_returns wr
  GROUP BY 
    wr.wr_item_sk
),
ItemDetails AS (
  SELECT 
    i.i_item_id,
    i.i_product_name,
    COALESCE(tc.total_returned_quantity, 0) AS total_returned_quantity,
    COALESCE(tc.total_returned_amount, 0) AS total_returned_amount,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    COALESCE(SUM(ws.ws_ext_sales_price), 0) AS total_sales
  FROM 
    item i
  LEFT JOIN 
    TotalReturns tc ON i.i_item_sk = tc.wr_item_sk
  LEFT JOIN 
    web_sales ws ON i.i_item_sk = ws.ws_item_sk
  GROUP BY 
    i.i_item_id,
    i.i_product_name,
    tc.total_returned_quantity,
    tc.total_returned_amount
)
SELECT 
  id.i_item_id,
  id.i_product_name,
  id.total_returned_quantity,
  id.total_returned_amount,
  id.total_orders,
  id.total_sales,
  CASE 
    WHEN id.total_sales > 0 THEN (id.total_returned_amount / id.total_sales) * 100
    ELSE NULL 
  END AS return_rate_percentage,
  ROW_NUMBER() OVER (ORDER BY id.total_sales DESC) AS sales_rank
FROM 
  ItemDetails id
WHERE 
  id.total_orders > 0 
ORDER BY 
  return_rate_percentage DESC NULLS LAST
LIMIT 10;
