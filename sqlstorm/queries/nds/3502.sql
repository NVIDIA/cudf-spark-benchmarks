
WITH sales_summary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        c.c_current_addr_sk,
        ROW_NUMBER() OVER (PARTITION BY c.c_current_addr_sk ORDER BY cd.cd_purchase_estimate DESC) AS addr_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
),
top_items AS (
    SELECT 
        ss.ws_item_sk,
        it.i_item_desc,
        it.i_current_price,
        ss.total_quantity,
        ss.total_sales
    FROM 
        sales_summary ss
    JOIN 
        item it ON ss.ws_item_sk = it.i_item_sk
    WHERE 
        ss.sales_rank <= 10
)
SELECT 
    ci.c_customer_sk,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.c_current_addr_sk,
    ti.i_item_desc,
    ti.total_quantity,
    ti.total_sales,
    (CASE 
        WHEN ci.cd_marital_status = 'M' THEN 'Married'
        ELSE 'Single'
    END) AS marital_status_type,
    (SELECT AVG(total_sales) FROM top_items) AS avg_top_item_sales,
    ti.i_current_price * NULLIF(ti.total_quantity, 0) AS total_transaction_value
FROM 
    customer_info ci
LEFT JOIN 
    top_items ti ON ci.addr_rank = 1
WHERE 
    ci.addr_rank <= 5 OR NULLIF(ti.total_sales, 0) > 5000
ORDER BY 
    ci.c_customer_sk, ti.total_sales DESC;
