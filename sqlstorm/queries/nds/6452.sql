
WITH regional_sales AS (
    SELECT 
        s.s_store_id,
        s.s_store_name,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
        AVG(ss.ss_sales_price) AS avg_sales_price
    FROM 
        store s
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    WHERE 
        ss.ss_sold_date_sk BETWEEN (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023) - 30 
                                AND (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        s.s_store_id, s.s_store_name
),
customer_info AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(ss.ss_ticket_number) AS purchase_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
employee_sales AS (
    SELECT 
        w.w_warehouse_id, 
        COUNT(ss.ss_ticket_number) AS employee_handled_sales
    FROM 
        warehouse w
    JOIN 
        store_sales ss ON w.w_warehouse_sk = ss.ss_store_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    rs.s_store_id,
    rs.s_store_name,
    rs.total_sales,
    rs.total_transactions,
    rs.avg_sales_price,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.purchase_count,
    es.employee_handled_sales
FROM 
    regional_sales rs
JOIN 
    customer_info ci ON ci.purchase_count > 0
JOIN 
    employee_sales es ON es.w_warehouse_id = rs.s_store_id
ORDER BY 
    rs.total_sales DESC
LIMIT 10;
