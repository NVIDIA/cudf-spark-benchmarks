
WITH  MonthlySales AS (
    SELECT 
        d.d_year, 
        d.d_month_seq, 
        SUM(ss.ss_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY d.d_year ORDER BY SUM(ss.ss_sales_price) DESC) AS sales_rank
    FROM 
        date_dim d
    JOIN 
        store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year, d.d_month_seq
),
TopStores AS (
    SELECT 
        s.s_store_id, 
        s.s_store_name, 
        d.d_year, 
        SUM(ss.ss_sales_price) AS total_sales
    FROM 
        store s 
    JOIN 
        store_sales ss ON ss.ss_store_sk = s.s_store_sk
    JOIN 
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year IN (2022, 2023)
    GROUP BY 
        s.s_store_id, s.s_store_name, d.d_year
),
Promotions AS (
    SELECT 
        p.p_promo_id, 
        p.p_promo_name, 
        COUNT(ws.ws_order_number) AS promo_usage_count
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_id, p.p_promo_name
    HAVING 
        COUNT(ws.ws_order_number) > 100
)
SELECT 
    d.d_year,
    d.d_month_seq,
    COALESCE(m.total_sales, 0) AS monthly_sales,
    COALESCE(t.s_store_name, 'Unknown Store') AS top_store_name,
    COALESCE(t.total_sales, 0) AS top_store_sales,
    COALESCE(p.p_promo_name, 'No Promotion') AS promotion_name,
    COALESCE(p.promo_usage_count, 0) AS promotion_usage
FROM 
    date_dim d
LEFT JOIN 
    MonthlySales m ON d.d_year = m.d_year AND d.d_month_seq = m.d_month_seq
LEFT JOIN 
    TopStores t ON d.d_year = t.d_year
LEFT JOIN 
    Promotions p ON p.promo_usage_count > 0
WHERE 
    d.d_year BETWEEN 2020 AND 2023
ORDER BY 
    d.d_year, d.d_month_seq;
