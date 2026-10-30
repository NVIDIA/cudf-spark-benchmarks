
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_sales_price) AS total_spent,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_sales_price) DESC) AS rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ws.ws_sold_date_sk >= (SELECT DENSE_RANK() OVER (ORDER BY d.d_date) 
                                FROM date_dim d 
                                WHERE d.d_year = 2022 
                                AND d.d_month_seq <= 6 
                                ORDER BY d.d_date DESC LIMIT 1) 
        AND ws.ws_sold_date_sk <= (SELECT MAX(d.d_date_sk)
                                    FROM date_dim d
                                    WHERE d.d_year = 2022)
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),

top_customers AS (
    SELECT 
        customer_summary.c_customer_sk,
        customer_summary.order_count,
        customer_summary.total_spent,
        customer_summary.cd_gender,
        customer_summary.cd_marital_status
    FROM 
        customer_summary
    WHERE 
        customer_summary.rank <= 10
)

SELECT 
    ca.ca_city,
    SUM(tc.total_spent) AS total_spent_by_city,
    COUNT(tc.c_customer_sk) AS total_customers
FROM 
    top_customers tc
LEFT JOIN 
    customer_address ca ON tc.c_customer_sk = ca.ca_address_sk
GROUP BY 
    ca.ca_city
HAVING 
    SUM(tc.total_spent) IS NOT NULL
ORDER BY 
    total_spent_by_city DESC;
