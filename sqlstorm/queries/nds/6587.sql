
WITH sales_data AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ck.c_customer_id,
        ck.c_first_name,
        ck.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        dd.d_year,
        dd.d_month_seq,
        dd.d_week_seq
    FROM 
        web_sales ws
        JOIN customer ck ON ws.ws_bill_customer_sk = ck.c_customer_sk
        JOIN customer_demographics cd ON ck.c_current_cdemo_sk = cd.cd_demo_sk
        JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
        AND dd.d_month_seq IN (1, 2, 3)
),
aggregated_sales AS (
    SELECT 
        d_year,
        d_month_seq,
        d_week_seq,
        cd_gender,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT c_customer_id) AS unique_customers
    FROM 
        sales_data
    GROUP BY 
        d_year, d_month_seq, d_week_seq, cd_gender
)
SELECT 
    d_year,
    d_month_seq,
    d_week_seq,
    cd_gender,
    total_quantity,
    total_sales,
    unique_customers,
    ROUND(total_sales / NULLIF(unique_customers, 0), 2) AS avg_sales_per_customer
FROM 
    aggregated_sales
ORDER BY 
    d_year ASC, d_month_seq ASC, d_week_seq ASC, cd_gender;
