
WITH  cte_sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_quantity) AS total_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 1000 AND 2000
    GROUP BY 
        ws_item_sk
),
top_items AS (
    SELECT 
        cte.ws_item_sk,
        cte.total_sales,
        cte.total_quantity,
        ROW_NUMBER() OVER (ORDER BY cte.total_sales DESC) AS item_rank
    FROM 
        cte_sales_summary cte
    WHERE 
        cte.sales_rank <= 10
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_paid) AS total_paid
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_marital_status = 'M'
    GROUP BY 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status
),
sales_ranked AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.total_paid,
        RANK() OVER (ORDER BY ci.total_paid DESC) AS paid_rank
    FROM 
        customer_info ci
)
SELECT 
    sr.c_customer_sk,
    sr.c_first_name,
    sr.c_last_name,
    sr.cd_gender,
    sr.cd_marital_status,
    sr.total_paid,
    ti.ws_item_sk,
    ti.total_sales,
    ti.total_quantity
FROM 
    sales_ranked sr
LEFT JOIN 
    top_items ti ON sr.total_paid > ti.total_sales
WHERE 
    sr.paid_rank <= 50
    AND (sr.cd_gender IS NOT NULL OR sr.cd_marital_status IS NOT NULL)
ORDER BY 
    sr.total_paid DESC,
    ti.total_sales DESC
LIMIT 100;
