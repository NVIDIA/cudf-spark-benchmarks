
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        ss.ss_sold_date_sk BETWEEN 2450000 AND 2450599 
    GROUP BY 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status
), 
SalesOverview AS (
    SELECT 
        cs.cd_gender,
        cs.cd_marital_status,
        COUNT(DISTINCT cs.c_customer_sk) AS customer_count,
        SUM(cs.total_sales) AS total_revenue,
        AVG(cs.total_sales) AS avg_sales_per_customer,
        SUM(cs.total_transactions) AS total_transactions
    FROM 
        CustomerStats AS cs
    GROUP BY 
        cs.cd_gender, 
        cs.cd_marital_status
)
SELECT 
    so.cd_gender, 
    so.cd_marital_status, 
    so.customer_count, 
    so.total_revenue, 
    so.avg_sales_per_customer, 
    so.total_transactions,
    CASE 
        WHEN so.avg_sales_per_customer > 1000 THEN 'High Value'
        WHEN so.avg_sales_per_customer BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value' 
    END AS customer_value_segment
FROM 
    SalesOverview AS so
ORDER BY 
    so.total_revenue DESC;
