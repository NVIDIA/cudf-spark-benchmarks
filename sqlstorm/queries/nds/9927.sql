WITH sales_data AS (
    SELECT 
        ws.ws_bill_customer_sk,
        c.c_current_cdemo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20000101 AND 20001231 
    GROUP BY 
        ws.ws_bill_customer_sk, c.c_current_cdemo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
ranked_sales AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY cd_gender ORDER BY total_sales DESC) AS sales_rank
    FROM 
        sales_data
)
SELECT 
    rs.cd_gender,
    COUNT(*) AS number_of_customers,
    AVG(rs.total_sales) AS avg_sales,
    MAX(rs.total_sales) AS max_sales,
    MIN(rs.total_sales) AS min_sales
FROM 
    ranked_sales rs
WHERE 
    rs.sales_rank <= 10 
GROUP BY 
    rs.cd_gender
ORDER BY 
    rs.cd_gender;