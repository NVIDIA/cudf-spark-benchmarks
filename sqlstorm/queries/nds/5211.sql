
WITH sales_summary AS (
    SELECT 
        d.d_year,
        SUM(ss_net_paid) AS total_sales,
        COUNT(DISTINCT ss_ticket_number) AS total_transactions,
        SUM(ss_quantity) AS total_units_sold
    FROM 
        store_sales
    JOIN 
        date_dim d ON ss_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2021 AND 2023
    GROUP BY 
        d.d_year
),
customer_info AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
warehouse_performance AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ss_net_profit) AS total_profit,
        AVG(ss_net_paid) AS avg_transaction_value
    FROM 
        warehouse w
    JOIN 
        store_sales ss ON w.w_warehouse_sk = ss.ss_store_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    ss.d_year,
    ss.total_sales,
    ss.total_transactions,
    ss.total_units_sold,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ci.customer_count,
    wp.w_warehouse_id,
    wp.total_profit,
    wp.avg_transaction_value
FROM 
    sales_summary ss
JOIN 
    customer_info ci ON (ci.customer_count > 100)
JOIN 
    warehouse_performance wp ON (wp.total_profit > 10000)
ORDER BY 
    ss.total_sales DESC, wp.avg_transaction_value DESC;
