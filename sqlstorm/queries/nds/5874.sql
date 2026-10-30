
WITH ranked_customers AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_purchase_estimate > 1000
        AND ws.ws_sold_date_sk >= (SELECT MIN(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
        AND ws.ws_sold_date_sk <= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, cd.cd_credit_rating
),
top_customers AS (
    SELECT 
        rc.c_customer_id,
        rc.cd_gender,
        rc.cd_marital_status,
        rc.cd_purchase_estimate,
        rc.cd_credit_rating,
        rc.total_sales
    FROM ranked_customers rc
    WHERE rc.sales_rank <= 10
),
sales_summary AS (
    SELECT 
        cnt.cd_gender,
        COUNT(cnt.c_customer_id) AS customer_count,
        SUM(cnt.total_sales) AS total_sales_value,
        AVG(cnt.total_sales) AS avg_sales_per_customer
    FROM 
        top_customers cnt
    GROUP BY 
        cnt.cd_gender
)
SELECT 
    ss.cd_gender,
    ss.customer_count,
    ss.total_sales_value,
    ss.avg_sales_per_customer,
    CASE 
        WHEN ss.avg_sales_per_customer > 5000 THEN 'High Value'
        WHEN ss.avg_sales_per_customer BETWEEN 3000 AND 5000 THEN 'Medium Value'
        ELSE 'Low Value' 
    END AS customer_value_segment
FROM 
    sales_summary ss
ORDER BY 
    ss.total_sales_value DESC;
