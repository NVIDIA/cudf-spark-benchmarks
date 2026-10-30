
WITH sales_summary AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 
        AND cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'M'
    GROUP BY 
        c.c_customer_id
),
top_sales AS (
    SELECT 
        c.c_customer_id,
        ss.total_quantity,
        ss.total_sales,
        ss.total_discount,
        ss.total_orders,
        RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
    FROM 
        sales_summary ss
    JOIN 
        customer c ON ss.c_customer_id = c.c_customer_id
)
SELECT 
    ts.c_customer_id,
    ts.total_quantity,
    ts.total_sales,
    ts.total_discount,
    ts.total_orders,
    ts.sales_rank
FROM 
    top_sales ts
WHERE 
    ts.sales_rank <= 10 
ORDER BY 
    ts.total_sales DESC;
