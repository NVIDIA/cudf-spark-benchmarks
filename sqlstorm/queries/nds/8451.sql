
WITH sales_summary AS (
    SELECT 
        d_year,
        d_month_seq,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        AVG(ws_net_paid) AS avg_order_value,
        SUM(ws_quantity) AS total_quantity
    FROM 
        web_sales w
    JOIN 
        date_dim d ON w.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON w.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 1990
    GROUP BY 
        d_year, d_month_seq
), average_discount AS (
    SELECT 
        d_year,
        d_month_seq,
        AVG(ws_ext_discount_amt) AS avg_discount
    FROM 
        web_sales w
    JOIN 
        date_dim d ON w.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d_year, d_month_seq
)
SELECT 
    s.d_year,
    s.d_month_seq,
    s.total_sales,
    s.order_count,
    s.avg_order_value,
    s.total_quantity,
    COALESCE(ad.avg_discount, 0) AS avg_discount
FROM 
    sales_summary s
LEFT JOIN 
    average_discount ad ON s.d_year = ad.d_year AND s.d_month_seq = ad.d_month_seq
ORDER BY 
    s.d_year, s.d_month_seq
LIMIT 100;
