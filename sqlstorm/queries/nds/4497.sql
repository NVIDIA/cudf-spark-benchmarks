
WITH customer_sales AS (
  SELECT 
    c.c_customer_id,
    SUM(ws.ws_net_paid_inc_tax) AS total_sales,
    COUNT(DISTINCT ws.ws_order_number) AS order_count
  FROM 
    customer c
  JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
  GROUP BY 
    c.c_customer_id
),
promotion_summary AS (
  SELECT 
    p.p_promo_id,
    COUNT(DISTINCT ws.ws_order_number) AS promo_order_count,
    SUM(ws.ws_net_paid_inc_tax) AS total_promo_sales
  FROM 
    promotion p
  LEFT JOIN 
    web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
  GROUP BY 
    p.p_promo_id
),
high_value_customers AS (
  SELECT 
    cs.c_customer_id,
    cs.total_sales,
    ROW_NUMBER() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
  FROM 
    customer_sales cs
  WHERE 
    cs.total_sales > 1000
),
desired_promotions AS (
  SELECT 
    ps.p_promo_id,
    ps.total_promo_sales,
    ROW_NUMBER() OVER (ORDER BY ps.total_promo_sales DESC) AS promo_rank
  FROM 
    promotion_summary ps
  WHERE 
    ps.promo_order_count > 0 AND ps.total_promo_sales > 500
)
SELECT 
  hc.c_customer_id,
  hc.total_sales,
  dp.p_promo_id,
  dp.total_promo_sales
FROM 
  high_value_customers hc
FULL OUTER JOIN 
  desired_promotions dp ON hc.total_sales > 1500 AND dp.total_promo_sales < 3000
WHERE 
  hc.sales_rank <= 10 OR dp.promo_rank <= 5
ORDER BY 
  hc.total_sales DESC, dp.total_promo_sales DESC;
