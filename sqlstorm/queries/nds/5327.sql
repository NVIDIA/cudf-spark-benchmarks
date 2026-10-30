
WITH sales_data AS (
    SELECT 
        ws.ws_ship_date_sk,
        d.d_year,
        d.d_quarter_seq,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        ws.ws_ship_date_sk, d.d_year, d.d_quarter_seq
), 
average_sales AS (
    SELECT 
        d_year,
        d_quarter_seq,
        AVG(total_sales) AS avg_sales,
        AVG(total_discount) AS avg_discount,
        AVG(order_count) AS avg_orders,
        AVG(unique_customers) AS avg_customers
    FROM 
        sales_data
    GROUP BY 
        d_year, d_quarter_seq
)
SELECT 
    a.d_year,
    a.d_quarter_seq,
    a.avg_sales,
    a.avg_discount,
    a.avg_orders,
    a.avg_customers,
    CASE 
        WHEN a.avg_sales > b.avg_sales THEN 'Increase'
        WHEN a.avg_sales < b.avg_sales THEN 'Decrease'
        ELSE 'Stable'
    END AS sales_trend
FROM 
    average_sales a
LEFT JOIN 
    average_sales b ON a.d_year = b.d_year AND a.d_quarter_seq = b.d_quarter_seq + 1
ORDER BY 
    a.d_year, a.d_quarter_seq;
