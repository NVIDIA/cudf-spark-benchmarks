
WITH RankedSales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rn,
        SUM(ws.ws_sales_price) OVER (PARTITION BY ws.ws_item_sk) AS total_sales
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
),
Promotions AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_name,
        SUM(cs.cs_ext_sales_price) AS total_promo_sales
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE p.p_start_date_sk BETWEEN 2450000 AND 2450600
    GROUP BY p.p_promo_sk, p.p_promo_name
),
CustomerSegments AS (
    SELECT
        cd.cd_demo_sk,
        SUM(ws.ws_sales_price) AS segment_sales,
        COUNT(DISTINCT c.c_customer_id) AS num_customers,
        MAX(cd.cd_purchase_estimate) AS max_purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY cd.cd_demo_sk
)
SELECT
    r.ws_item_sk,
    r.ws_order_number,
    r.ws_quantity,
    r.ws_sales_price,
    ps.total_promo_sales,
    cs.segment_sales,
    cs.num_customers,
    cs.max_purchase_estimate,
    COALESCE(r.total_sales, 0) AS total_sales
FROM RankedSales r
LEFT JOIN Promotions ps ON r.ws_item_sk = ps.total_promo_sales
LEFT JOIN CustomerSegments cs ON r.ws_item_sk = cs.cd_demo_sk
WHERE r.rn = 1
  AND (r.ws_sales_price > 20 OR r.ws_quantity IS NULL)
  AND ps.total_promo_sales IS NOT NULL
ORDER BY r.ws_item_sk, r.ws_order_number;
