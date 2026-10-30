
WITH customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        dd.d_year,
        dd.d_month_seq,
        SUM(ws.ws_sales_price) AS total_spent,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_purchase_estimate, 
        dd.d_year, 
        dd.d_month_seq
), ranked_customers AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_spent DESC) AS rank
    FROM 
        customer_data
)
SELECT 
    rc.c_customer_sk,
    rc.c_first_name,
    rc.c_last_name,
    rc.cd_gender,
    rc.cd_marital_status,
    rc.cd_purchase_estimate,
    rc.d_year,
    rc.d_month_seq,
    rc.total_spent,
    rc.order_count
FROM 
    ranked_customers rc
WHERE 
    rc.rank <= 10
ORDER BY 
    rc.d_year, 
    rc.total_spent DESC;
