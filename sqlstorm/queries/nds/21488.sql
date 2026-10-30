
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_net_paid,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (
            SELECT d.d_date_sk 
            FROM date_dim d 
            WHERE d.d_year = 2023 AND d.d_month_seq IN (6, 7, 8)
        )
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        COALESCE(cd.cd_marital_status, 'Unknown') AS marital_status,
        ROUND(AVG(COALESCE(cd.cd_purchase_estimate, 0)) OVER (PARTITION BY cd.cd_gender), 2) AS avg_purchase
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
store_web_sales AS (
    SELECT 
        s.s_store_id,
        SUM(ws.ws_net_paid) AS total_web_sales,
        SUM(ws.ws_quantity) AS total_web_quantity
    FROM 
        store s
    JOIN 
        web_sales ws ON s.s_store_sk = ws.ws_bill_addr_sk 
    WHERE 
        s.s_country = 'USA' 
    GROUP BY 
        s.s_store_id
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.marital_status,
    sws.s_store_id,
    sws.total_web_sales,
    sws.total_web_quantity,
    rt.ws_sales_price,
    rt.ws_net_paid,
    COALESCE(NULLIF(rt.sales_rank, 1), 0) AS non_top_rank
FROM 
    customer_info ci
LEFT JOIN 
    ranked_sales rt ON ci.c_customer_sk = rt.ws_item_sk
LEFT JOIN 
    store_web_sales sws ON sws.total_web_sales > 1000
WHERE 
    ci.avg_purchase > (SELECT AVG(cd.cd_purchase_estimate) FROM customer_demographics cd)
    AND rt.ws_sales_price IS NOT NULL
    AND sws.s_store_id IS NOT NULL
ORDER BY 
    ci.c_last_name, ci.c_first_name;
