
WITH customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_gender = 'F'
        AND cd.cd_purchase_estimate > 1000
),
sales_data AS (
    SELECT 
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ws.ws_ship_date_sk,
        c.c_customer_sk
    FROM 
        web_sales ws
    JOIN 
        customer_data c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        ws.ws_ship_date_sk, c.c_customer_sk
),
date_summary AS (
    SELECT 
        dd.d_date_sk,
        dd.d_month_seq,
        dd.d_year,
        SUM(s.total_sales) AS monthly_sales
    FROM 
        sales_data s
    JOIN 
        date_dim dd ON s.ws_ship_date_sk = dd.d_date_sk
    GROUP BY 
        dd.d_date_sk, dd.d_month_seq, dd.d_year
)

SELECT 
    ds.d_year,
    ds.d_month_seq,
    SUM(ds.monthly_sales) AS aggregate_monthly_sales
FROM 
    date_summary ds
WHERE 
    ds.monthly_sales IS NOT NULL
GROUP BY 
    ds.d_year, ds.d_month_seq
ORDER BY 
    ds.d_year ASC, ds.d_month_seq ASC;
