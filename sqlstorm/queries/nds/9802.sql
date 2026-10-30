
WITH Customer_Sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        AVG(ws.ws_net_paid) AS avg_order_value
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_id
),
High_Value_Customers AS (
    SELECT 
        c.c_customer_id,
        cs.total_sales,
        cs.order_count,
        cs.total_discount,
        cs.avg_order_value,
        ROW_NUMBER() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        Customer_Sales cs
    JOIN 
        customer c ON cs.c_customer_id = c.c_customer_id
    WHERE 
        cs.total_sales > 1000
)
SELECT 
    h.c_customer_id AS customer_id,
    h.total_sales,
    h.order_count,
    h.total_discount,
    h.avg_order_value,
    d.d_day_name,
    d.d_month_seq
FROM 
    High_Value_Customers h
JOIN 
    date_dim d ON h.c_customer_id = d.d_date_id
WHERE 
    h.sales_rank <= 10
ORDER BY 
    h.total_sales DESC;
