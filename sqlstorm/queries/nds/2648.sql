
WITH sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        AVG(ws_net_paid) AS avg_order_value,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
customer_details AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        dd.d_year,
        h.hd_income_band_sk
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        household_demographics h ON c.c_current_hdemo_sk = h.hd_demo_sk
    JOIN 
        date_dim dd ON dd.d_date_sk = c.c_first_sales_date_sk
    WHERE 
        (cd.cd_marital_status = 'M' OR cd.cd_marital_status IS NULL)
        AND (cd.cd_gender = 'F' OR cd.cd_gender IS NULL)
)
SELECT 
    cd.c_first_name,
    cd.c_last_name,
    cd.ca_city,
    cd.ca_state,
    cd.hd_income_band_sk,
    ss.total_sales,
    ss.order_count,
    ss.avg_order_value
FROM 
    customer_details cd
LEFT JOIN 
    sales_summary ss ON cd.c_customer_sk = ss.ws_bill_customer_sk
WHERE 
    ss.sales_rank <= 10
ORDER BY 
    total_sales DESC
LIMIT 100
