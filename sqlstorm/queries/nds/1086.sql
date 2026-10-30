
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        COUNT(DISTINCT ws.ws_web_page_sk) AS pages_visited
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
ranked_customers AS (
    SELECT 
        cs.*,
        RANK() OVER (ORDER BY total_spent DESC) AS rank
    FROM 
        customer_sales cs
)
SELECT 
    rc.c_customer_sk,
    rc.c_first_name,
    rc.c_last_name,
    rc.total_spent,
    rc.order_count,
    rc.pages_visited,
    COALESCE(cd.cd_gender, 'Unknown') AS gender,
    COALESCE(hd.hd_income_band_sk, 0) AS income_band,
    CASE 
        WHEN rc.total_spent > 1000 THEN 'High Value'
        WHEN rc.total_spent BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    ranked_customers rc
LEFT JOIN 
    customer_demographics cd ON rc.c_customer_sk = cd.cd_demo_sk
LEFT JOIN 
    household_demographics hd ON rc.c_customer_sk = hd.hd_demo_sk
WHERE 
    rc.rank <= 100
ORDER BY 
    rc.total_spent DESC;
