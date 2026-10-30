
WITH  sales_cte AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rn
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk
), 
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
top_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_web_sales,
        RANK() OVER (ORDER BY cs.total_web_sales DESC) AS sales_rank
    FROM customer_summary cs
    WHERE cs.total_web_sales IS NOT NULL
),
inventory_check AS (
    SELECT 
        inv.inv_item_sk,
        i.i_item_desc,
        COALESCE(SUM(inv.inv_quantity_on_hand), 0) AS total_inventory
    FROM inventory inv
    LEFT JOIN item i ON inv.inv_item_sk = i.i_item_sk
    GROUP BY inv.inv_item_sk, i.i_item_desc
),
return_analysis AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_value
    FROM store_returns
    GROUP BY sr_item_sk
),
final_report AS (
    SELECT 
        tc.c_customer_sk,
        tc.total_web_sales,
        i_check.i_item_desc,
        rv.total_returns,
        rv.total_return_value,
        (COALESCE(tc.total_web_sales, 0) - COALESCE(rv.total_return_value, 0)) AS net_sales,
        CASE
            WHEN tc.sales_rank <= 10 THEN 'Top Customer'
            ELSE 'Regular Customer'
        END AS customer_type
    FROM top_customers tc
    LEFT JOIN inventory_check i_check ON i_check.inv_item_sk = tc.c_customer_sk
    LEFT JOIN return_analysis rv ON rv.sr_item_sk = tc.c_customer_sk
)
SELECT 
    customer_type,
    COUNT(*) AS customer_count,
    AVG(net_sales) AS avg_net_sales
FROM final_report
GROUP BY customer_type
ORDER BY customer_count DESC;
