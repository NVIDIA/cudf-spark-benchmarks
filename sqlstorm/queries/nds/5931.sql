
WITH customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_current_cdemo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk > (SELECT MAX(d.d_date_sk) - 30 FROM date_dim d)
    GROUP BY c.c_customer_sk, c.c_current_cdemo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
warehouse_performance AS (
    SELECT 
        w.w_warehouse_sk,
        w.w_warehouse_name,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(ws.ws_net_paid) AS avg_net_paid
    FROM warehouse w
    JOIN web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY w.w_warehouse_sk, w.w_warehouse_name
),
demographic_summary AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(*) AS customer_count,
        SUM(cd.cd_purchase_estimate) AS total_purchase_estimate
    FROM customer_demographics cd
    JOIN customer_data cd_data ON cd.cd_demo_sk = cd_data.c_current_cdemo_sk
    GROUP BY cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
)
SELECT 
    cs.c_customer_sk,
    cs.order_count,
    cs.total_sales,
    wp.w_warehouse_name,
    wp.total_profit,
    wp.avg_net_paid,
    ds.customer_count,
    ds.total_purchase_estimate
FROM customer_data cs
JOIN warehouse_performance wp ON cs.total_sales > 1000.00
JOIN demographic_summary ds ON cs.cd_gender = ds.cd_gender AND cs.cd_marital_status = ds.cd_marital_status
WHERE ds.customer_count > 10
ORDER BY total_sales DESC, total_profit DESC;
