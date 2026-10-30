
WITH sales_summary AS (
    SELECT 
        s.s_store_id,
        SUM(ss.ss_quantity) AS total_quantity_sold,
        SUM(ss.ss_net_paid) AS total_revenue,
        AVG(ss.ss_net_paid) AS avg_order_value,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_sales_count
    FROM 
        store s
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    WHERE 
        ss.ss_sold_date_sk BETWEEN 1000 AND 2000
    GROUP BY 
        s.s_store_id
),
customer_data AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_quantity) AS total_quantity_purchased,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_ship_date_sk BETWEEN 1000 AND 2000
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
final_report AS (
    SELECT 
        ss.s_store_id,
        cs.c_customer_id,
        cs.cd_gender,
        cs.cd_marital_status,
        ss.total_quantity_sold,
        ss.total_revenue,
        cs.total_quantity_purchased,
        cs.total_spent,
        (ss.total_revenue / NULLIF(ss.total_quantity_sold, 0)) AS revenue_per_item,
        (cs.total_spent / NULLIF(cs.total_quantity_purchased, 0)) AS avg_spent_per_item
    FROM 
        sales_summary ss
    JOIN 
        customer_data cs ON ss.s_store_id = cs.c_customer_id
)
SELECT 
    s_store_id AS store_id,
    c_customer_id AS customer_id,
    cd_gender,
    cd_marital_status,
    total_quantity_sold,
    total_revenue,
    total_quantity_purchased,
    total_spent,
    revenue_per_item,
    avg_spent_per_item
FROM 
    final_report
ORDER BY 
    total_revenue DESC;
