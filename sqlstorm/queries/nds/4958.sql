
WITH customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_current_cdemo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count,
        cd.cd_dep_college_count,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_sales_price) AS total_sales
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_current_cdemo_sk, cd.cd_gender, cd.cd_marital_status, 
        cd.cd_education_status, cd.cd_purchase_estimate, cd.cd_credit_rating, 
        cd.cd_dep_count, cd.cd_dep_employed_count, cd.cd_dep_college_count
),
warehouse_summary AS (
    SELECT 
        w.w_warehouse_sk,
        w.w_warehouse_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        warehouse w
    LEFT JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_sk, w.w_warehouse_name
),
ranked_customers AS (
    SELECT 
        cd.*,
        DENSE_RANK() OVER (ORDER BY cd.total_sales DESC) AS sales_rank
    FROM 
        customer_data cd
)
SELECT 
    rc.c_customer_sk,
    rc.cd_gender,
    rc.cd_marital_status,
    rc.cd_education_status,
    rc.cd_purchase_estimate,
    rc.total_sales,
    rc.order_count,
    ws.w_warehouse_name,
    ws.total_sales AS warehouse_sales,
    COALESCE(ws.total_profit, 0) AS warehouse_profit
FROM 
    ranked_customers rc
LEFT JOIN 
    warehouse_summary ws ON rc.c_customer_sk BETWEEN (ws.w_warehouse_sk - 10) AND (ws.w_warehouse_sk + 10)
WHERE 
    rc.sales_rank <= 100
    AND (rc.cd_gender = 'F' OR rc.cd_marital_status = 'M')
ORDER BY 
    rc.total_sales DESC;
