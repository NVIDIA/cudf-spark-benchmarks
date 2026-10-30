
WITH SalesData AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_sales,
        SUM(ws_net_paid) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS rn
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk
),
TopItems AS (
    SELECT 
        item.i_item_sk,
        item.i_item_desc,
        sales.total_sales,
        sales.total_revenue,
        DENSE_RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM SalesData sales
    JOIN item ON sales.ws_item_sk = item.i_item_sk
    WHERE sales.total_sales > 0
),
CustomerSummary AS (
    SELECT 
        cust.c_customer_sk,
        COUNT(DISTINCT cust.c_current_cdemo_sk) AS demo_count,
        MAX(demo.cd_purchase_estimate) AS max_purchase_estimate
    FROM customer cust
    LEFT JOIN customer_demographics demo ON cust.c_current_cdemo_sk = demo.cd_demo_sk
    GROUP BY cust.c_customer_sk
)
SELECT 
    ci.i_item_desc,
    ti.total_sales,
    ti.total_revenue,
    cs.c_customer_sk,
    cs.demo_count,
    cs.max_purchase_estimate
FROM TopItems ti
LEFT JOIN CustomerSummary cs ON cs.demo_count > 5
LEFT JOIN item ci ON ti.i_item_sk = ci.i_item_sk
WHERE ti.revenue_rank <= 10 
AND (cs.max_purchase_estimate IS NULL OR cs.max_purchase_estimate >= 100)
ORDER BY ti.total_revenue DESC;
