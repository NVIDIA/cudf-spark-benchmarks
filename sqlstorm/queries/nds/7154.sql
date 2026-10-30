
WITH sales_summary AS (
    SELECT 
        d.d_year, 
        d.d_month_seq, 
        d.d_quarter_seq, 
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_ship_customer_sk) AS unique_customers,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        d.d_year = 2022 
        AND cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'M'
    GROUP BY 
        d.d_year, d.d_month_seq, d.d_quarter_seq
)
SELECT 
    d_year,
    d_month_seq,
    d_quarter_seq,
    total_sales,
    total_orders,
    unique_customers,
    avg_sales_price,
    RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM 
    sales_summary
WHERE 
    total_sales > 100000
ORDER BY 
    total_sales DESC;
