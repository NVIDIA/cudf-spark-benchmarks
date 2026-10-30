
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS average_net_profit,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        d.d_year
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2021 AND 2023
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, d.d_year
),
ranked_sales AS (
    SELECT 
        c.c_customer_id AS customer_id, 
        total_sales, 
        average_net_profit, 
        cd_gender, 
        cd_marital_status, 
        cd_education_status,
        d_year,
        RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
    FROM 
        customer_sales c
)
SELECT 
    customer_id, 
    total_sales, 
    average_net_profit, 
    cd_gender, 
    cd_marital_status, 
    cd_education_status, 
    d_year
FROM 
    ranked_sales
WHERE 
    sales_rank <= 10
ORDER BY 
    d_year, total_sales DESC;
