
WITH  sales_data AS (
    SELECT 
        ss_item_sk,
        COUNT(ss_ticket_number) AS total_sales,
        SUM(ss_net_paid) AS total_revenue,
        RANK() OVER (PARTITION BY ss_item_sk ORDER BY SUM(ss_net_paid) DESC) AS sales_rank
    FROM 
        store_sales
    GROUP BY 
        ss_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
),
top_sales AS (
    SELECT 
        sd.ss_item_sk,
        sd.total_sales,
        sd.total_revenue,
        ROW_NUMBER() OVER (ORDER BY sd.total_revenue DESC) AS rank
    FROM 
        sales_data sd
    WHERE 
        sd.sales_rank = 1
    LIMIT 10
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_purchase_estimate,
    ts.total_sales,
    ts.total_revenue
FROM 
    top_sales ts
JOIN 
    web_sales ws ON ts.ss_item_sk = ws.ws_item_sk
JOIN 
    customer_info ci ON ws.ws_bill_customer_sk = ci.c_customer_sk
LEFT JOIN 
    warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
WHERE 
    (ci.cd_gender = 'F' OR ci.cd_gender = 'M')
    AND ci.cd_purchase_estimate > 1000
    AND w.w_country IS NOT NULL
ORDER BY 
    ts.total_revenue DESC;
