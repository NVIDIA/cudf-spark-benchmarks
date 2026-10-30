
WITH sales_summary AS (
    SELECT 
        sd.d_year AS sales_year,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS transaction_count,
        AVG(ss.ss_sales_price) AS avg_sales_price,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT ss.ss_customer_sk) AS unique_customers
    FROM 
        store_sales ss
    JOIN 
        date_dim sd ON ss.ss_sold_date_sk = sd.d_date_sk
    JOIN 
        store s ON ss.ss_store_sk = s.s_store_sk
    WHERE 
        sd.d_year BETWEEN 2021 AND 2023
        AND s.s_state = 'CA'
    GROUP BY 
        sd.d_year
),
customer_metrics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
),
final_report AS (
    SELECT 
        ss.sales_year,
        ss.total_sales,
        ss.transaction_count,
        ss.avg_sales_price,
        ss.total_discount,
        ss.unique_customers,
        cm.cd_gender,
        cm.cd_marital_status,
        cm.customer_count,
        cm.avg_purchase_estimate
    FROM 
        sales_summary ss
    CROSS JOIN 
        customer_metrics cm
)
SELECT 
    sales_year,
    total_sales,
    transaction_count,
    avg_sales_price,
    total_discount,
    unique_customers,
    cd_gender,
    cd_marital_status,
    customer_count,
    avg_purchase_estimate
FROM 
    final_report
ORDER BY 
    sales_year DESC, total_sales DESC;
