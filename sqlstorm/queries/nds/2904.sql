
WITH sales_summary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
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
        c.c_current_cdemo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
top_sales AS (
    SELECT 
        ss.ws_item_sk,
        ss.total_quantity,
        ss.total_sales,
        ci.c_customer_sk,
        ci.cd_gender,
        ci.cd_marital_status
    FROM 
        sales_summary ss
    INNER JOIN 
        customer_info ci ON ss.total_quantity > 1000 
    WHERE 
        ci.purchase_rank <= 10
)
SELECT 
    ts.ws_item_sk,
    ts.total_quantity,
    ts.total_sales,
    COALESCE(ci.cd_gender, 'Unknown') AS gender,
    COUNT(DISTINCT ts.c_customer_sk) AS unique_customers,
    SUM(CASE WHEN ci.cd_marital_status = 'M' THEN 1 ELSE 0 END) AS married_count,
    AVG(ts.total_sales) AS avg_sales
FROM 
    top_sales ts
LEFT JOIN 
    customer_info ci ON ts.c_customer_sk = ci.c_customer_sk
GROUP BY 
    ts.ws_item_sk, ts.total_quantity, ts.total_sales, ci.cd_gender
HAVING 
    SUM(ts.total_sales) > 5000
ORDER BY 
    avg_sales DESC;
