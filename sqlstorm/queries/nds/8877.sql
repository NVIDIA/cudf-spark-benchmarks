
WITH sales_summary AS (
    SELECT 
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        d.d_year,
        d.d_month_seq
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2021 AND 2023
    GROUP BY 
        c.c_first_name, c.c_last_name, d.d_year, d.d_month_seq
),
promotions_summary AS (
    SELECT 
        p.p_promo_name,
        SUM(ws.ws_quantity) AS promo_quantity,
        SUM(ws.ws_ext_sales_price) AS promo_sales
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_name
),
total_sales AS (
    SELECT 
        ss.c_first_name,
        ss.c_last_name,
        ss.total_quantity,
        ss.total_sales,
        ps.promo_quantity,
        ps.promo_sales,
        CASE 
            WHEN ps.promo_sales IS NOT NULL 
            THEN (ss.total_sales - ps.promo_sales) 
            ELSE ss.total_sales 
        END AS net_sales
    FROM 
        sales_summary ss
    LEFT JOIN 
        promotions_summary ps ON ss.total_quantity = ps.promo_quantity
)
SELECT 
    c_first_name,
    c_last_name,
    total_quantity,
    total_sales,
    promo_quantity,
    promo_sales,
    net_sales
FROM 
    total_sales
ORDER BY 
    net_sales DESC
LIMIT 100;
