
WITH ranked_sales AS (
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
best_sellers AS (
    SELECT 
        ir.i_item_id, 
        ir.i_item_desc, 
        r.total_quantity, 
        r.total_sales
    FROM 
        item ir
    JOIN 
        ranked_sales r ON ir.i_item_sk = r.ws_item_sk
    WHERE 
        r.sales_rank = 1
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender,
        COALESCE(cd.cd_marital_status, 'Unknown') AS marital_status
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
purchase_history AS (
    SELECT 
        si.ss_customer_sk,
        SUM(si.ss_net_paid_inc_tax) AS total_spent,
        COUNT(si.ss_ticket_number) AS purchase_count
    FROM 
        store_sales si
    GROUP BY 
        si.ss_customer_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.c_email_address,
    ci.gender,
    ci.marital_status,
    COALESCE(ph.total_spent, 0) AS total_spent,
    COALESCE(ph.purchase_count, 0) AS purchase_count,
    bs.i_item_id,
    bs.i_item_desc,
    bs.total_quantity,
    bs.total_sales
FROM 
    customer_info ci
LEFT JOIN 
    purchase_history ph ON ci.c_customer_sk = ph.ss_customer_sk
JOIN 
    best_sellers bs ON bs.total_sales > 1000
WHERE 
    ci.c_email_address IS NOT NULL
ORDER BY 
    total_spent DESC, 
    bs.total_sales DESC;
