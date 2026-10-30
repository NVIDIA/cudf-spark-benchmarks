WITH sales_data AS (
    SELECT 
        ws_sales_price,
        ws_ship_date_sk,
        cd_gender,
        cd_marital_status,
        d_year,
        d_month_seq,
        COUNT(DISTINCT ws_order_number) AS order_count,
        SUM(ws_sales_price) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON ws_ship_date_sk = d.d_date_sk
    WHERE 
        cd_gender = 'F' AND
        d_year = 2001 
    GROUP BY 
        ws_sales_price, 
        ws_ship_date_sk, 
        cd_gender, 
        cd_marital_status, 
        d_year, 
        d_month_seq
),
top_sales AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY d_month_seq ORDER BY total_sales DESC) AS rank
    FROM 
        sales_data
)
SELECT 
    d_month_seq,
    SUM(total_sales) AS month_total_sales,
    AVG(order_count) AS average_orders,
    MAX(total_sales) AS max_sales_amount
FROM 
    top_sales
WHERE 
    rank <= 5
GROUP BY 
    d_month_seq
ORDER BY 
    d_month_seq;