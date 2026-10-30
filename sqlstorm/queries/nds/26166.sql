
WITH AddressData AS (
  SELECT
    DISTINCT ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT c.c_customer_id) AS customer_count,
    SUM(CASE WHEN cd.cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count,
    SUM(CASE WHEN cd.cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
  FROM customer_address ca
  JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
  JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
  GROUP BY ca.ca_city, ca.ca_state
),
PromotionsStats AS (
  SELECT
    wd.p_promo_name,
    COUNT(DISTINCT ws.ws_order_number) AS sales_count,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_ext_discount_amt) AS total_discount
  FROM web_sales ws
  JOIN promotion wd ON ws.ws_promo_sk = wd.p_promo_sk
  GROUP BY wd.p_promo_name
)
SELECT
  ad.ca_city,
  ad.ca_state,
  ad.customer_count,
  ad.female_count,
  ad.male_count,
  ad.avg_purchase_estimate,
  ps.sales_count,
  ps.total_sales,
  ps.total_discount
FROM AddressData ad
LEFT JOIN PromotionsStats ps ON ad.customer_count > 100
ORDER BY ad.ca_state, ad.ca_city;
