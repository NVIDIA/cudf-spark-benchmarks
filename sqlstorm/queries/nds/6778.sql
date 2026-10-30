
WITH ranked_sales AS (
    SELECT 
        ss_customer_sk,
        SUM(ss_sales_price) AS total_sales,
        COUNT(ss_ticket_number) AS transaction_count,
        RANK() OVER (PARTITION BY ss_customer_sk ORDER BY SUM(ss_sales_price) DESC) AS sales_rank
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk BETWEEN 20230101 AND 20231231
    GROUP BY 
        ss_customer_sk
), customer_info AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        rs.total_sales,
        rs.transaction_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        ranked_sales rs ON c.c_customer_sk = rs.ss_customer_sk
    WHERE 
        rs.sales_rank <= 10
)
SELECT 
    ci.c_customer_id,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ci.cd_purchase_estimate,
    ci.ca_city,
    ci.ca_state,
    ci.total_sales,
    ci.transaction_count,
    d.d_year,
    d.d_month_seq,
    d.d_quarter_seq
FROM 
    customer_info ci
JOIN 
    date_dim d ON d.d_date BETWEEN '2023-01-01' AND '2023-12-31'
ORDER BY 
    ci.total_sales DESC;
