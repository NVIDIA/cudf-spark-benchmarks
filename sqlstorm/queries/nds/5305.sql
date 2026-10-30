
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
        AVG(ss.ss_sales_price) AS average_transaction_value
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
warehouse_summary AS (
    SELECT 
        w.w_warehouse_sk,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        AVG(ss.ss_ext_sales_price) AS average_sales_per_item
    FROM 
        warehouse AS w
    JOIN 
        store_sales AS ss ON w.w_warehouse_sk = ss.ss_store_sk
    GROUP BY 
        w.w_warehouse_sk
),
final_summary AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales AS customer_total_sales,
        cs.total_transactions,
        cs.average_transaction_value,
        ws.total_sales AS warehouse_total_sales,
        ws.average_sales_per_item
    FROM 
        customer_summary AS cs
    JOIN 
        warehouse_summary AS ws ON cs.total_sales >= ws.total_sales
)
SELECT 
    f.c_customer_sk,
    f.c_first_name,
    f.c_last_name,
    f.customer_total_sales,
    f.total_transactions,
    f.average_transaction_value,
    f.warehouse_total_sales,
    f.average_sales_per_item
FROM 
    final_summary AS f
WHERE 
    f.customer_total_sales > 1000
ORDER BY 
    f.customer_total_sales DESC
LIMIT 50;
