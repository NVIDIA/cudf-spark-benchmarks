
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk, 
        SUM(ws.ws_quantity) AS total_sales_quantity, 
        SUM(ws.ws_sales_price) AS total_sales_value,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        d.d_year,
        p.p_promo_name
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE 
        d.d_year BETWEEN 2021 AND 2023
    GROUP BY 
        ws.ws_item_sk, d.d_year, p.p_promo_name
),
SalesRanking AS (
    SELECT 
        sd.ws_item_sk, 
        sd.total_sales_quantity, 
        sd.total_sales_value, 
        sd.order_count,
        sd.d_year,
        RANK() OVER (PARTITION BY sd.d_year ORDER BY sd.total_sales_value DESC) AS sales_rank
    FROM 
        SalesData sd
)
SELECT 
    ir.i_item_id,
    ir.i_product_name,
    sr.total_sales_quantity,
    sr.total_sales_value,
    sr.order_count,
    sr.sales_rank,
    sr.d_year
FROM 
    SalesRanking sr
JOIN 
    item ir ON sr.ws_item_sk = ir.i_item_sk
WHERE 
    sr.sales_rank <= 10
ORDER BY 
    sr.d_year, sr.sales_rank;
