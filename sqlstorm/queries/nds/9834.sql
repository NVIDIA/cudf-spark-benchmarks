
WITH sales_data AS (
    SELECT 
        ws.ws_item_sk, 
        ws.ws_sales_price,
        ws.ws_quantity,
        c.c_customer_id,
        cad.ca_city,
        dd.d_year,
        dd.d_month_seq,
        dd.d_week_seq
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_address cad ON c.c_current_addr_sk = cad.ca_address_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2022
),
aggregated_sales AS (
    SELECT 
        ca_city,
        d_year,
        d_month_seq,
        SUM(ws_sales_price * ws_quantity) AS total_sales,
        COUNT(DISTINCT c_customer_id) AS unique_customers,
        COUNT(*) AS transaction_count
    FROM 
        sales_data
    GROUP BY 
        ca_city, d_year, d_month_seq
),
ranked_sales AS (
    SELECT 
        ca_city, 
        d_year, 
        d_month_seq,
        total_sales,
        unique_customers,
        transaction_count,
        RANK() OVER (PARTITION BY d_year, d_month_seq ORDER BY total_sales DESC) AS sales_rank
    FROM 
        aggregated_sales
)
SELECT 
    ca_city,
    d_year,
    d_month_seq,
    total_sales,
    unique_customers,
    transaction_count,
    sales_rank
FROM 
    ranked_sales
WHERE 
    sales_rank <= 10
ORDER BY 
    d_year, d_month_seq, sales_rank;
