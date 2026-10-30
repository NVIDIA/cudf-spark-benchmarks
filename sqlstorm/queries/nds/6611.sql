
WITH sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        SUM(ws.ws_ext_tax) AS total_tax,
        d.d_year AS sales_year,
        d.d_month_seq AS sales_month,
        c.c_birth_year AS customer_birth_year,
        p.p_promo_name AS promotion_name
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE 
        d.d_year = 2023 AND 
        c.c_birth_year IS NOT NULL
    GROUP BY 
        ws.ws_item_sk, d.d_year, d.d_month_seq, c.c_birth_year, p.p_promo_name
),
average_sales AS (
    SELECT 
        p_name,
        AVG(total_sales) AS avg_sales,
        AVG(total_discount) AS avg_discount,
        AVG(total_tax) AS avg_tax
    FROM 
        (SELECT 
            CASE 
                WHEN customer_birth_year < 1980 THEN 'Baby Boomer'
                WHEN customer_birth_year < 2000 THEN 'Generation X'
                ELSE 'Millennial/Gen Z'
            END AS p_name,
            total_sales,
            total_discount,
            total_tax
        FROM 
            sales_data) categorized_sales
    GROUP BY 
        p_name
)
SELECT 
    p_name,
    avg_sales,
    avg_discount,
    avg_tax,
    RANK() OVER (ORDER BY avg_sales DESC) AS sales_rank
FROM 
    average_sales
ORDER BY 
    sales_rank;
