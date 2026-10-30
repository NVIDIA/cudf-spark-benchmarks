
WITH  sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(*) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS order_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
), 
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        d.d_year,
        COALESCE(SUM(ws.ws_ext_sales_price), 0) AS total_online_spending
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, d.d_year
), 
top_customers AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.d_year,
        ci.total_online_spending,
        ss.total_orders
    FROM 
        customer_info ci
    JOIN 
        sales_summary ss ON ci.c_customer_sk = ss.ws_bill_customer_sk
    WHERE 
        ss.order_rank <= 10
)
SELECT 
    t.c_first_name,
    t.c_last_name,
    t.cd_gender,
    t.cd_marital_status,
    t.d_year,
    t.total_online_spending,
    CASE 
        WHEN t.total_online_spending IS NULL THEN 'No Spending'
        WHEN t.total_online_spending < 1000 THEN 'Low Spender'
        WHEN t.total_online_spending BETWEEN 1000 AND 5000 THEN 'Medium Spender'
        ELSE 'High Spender'
    END AS spender_category,
    RANK() OVER (ORDER BY t.total_online_spending DESC) AS spending_rank
FROM 
    top_customers t
WHERE 
    t.cd_gender = 'F'
ORDER BY 
    t.total_online_spending DESC;
