
WITH RankedSales AS (
    SELECT 
        w.ws_order_number,
        w.ws_item_sk,
        SUM(w.ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY w.ws_item_sk ORDER BY SUM(w.ws_sales_price) DESC) AS sales_rank,
        w.ws_ship_mode_sk,
        d.d_year,
        CASE 
            WHEN d.d_year BETWEEN 2020 AND 2023 THEN '2020s'
            ELSE 'Previous Decades'
        END AS decade,
        COALESCE(sm.sm_type, 'Unknown') AS shipping_type
    FROM 
        web_sales w
    JOIN 
        date_dim d ON w.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN 
        ship_mode sm ON w.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY 
        w.ws_order_number, w.ws_item_sk, w.ws_ship_mode_sk, d.d_year, sm.sm_type
), CustomerReturns AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returns,
        COUNT(DISTINCT cr.cr_returning_customer_sk) AS unique_returning_customers
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.cr_item_sk
), CombinedSales AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_sales,
        cs.total_returns,
        cs.unique_returning_customers,
        rs.sales_rank,
        rs.decade,
        rs.shipping_type
    FROM 
        RankedSales rs
    LEFT JOIN 
        CustomerReturns cs ON rs.ws_item_sk = cs.cr_item_sk
    WHERE 
        (rs.total_sales IS NOT NULL OR cs.total_returns IS NOT NULL)
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    COALESCE(cs.total_sales, 0) AS total_sales,
    COALESCE(cs.total_returns, 0) AS total_returns,
    cs.shipping_type,
    CASE 
        WHEN cs.total_sales > 5000 THEN 'High Value'
        WHEN cs.total_sales BETWEEN 1000 AND 5000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM 
    customer c
LEFT JOIN 
    CombinedSales cs ON c.c_customer_sk = cs.ws_item_sk
WHERE 
    (c.c_birth_month = 2 OR c.c_birth_day IS NULL)
AND 
    (cs.total_sales > 1000 OR cs.total_returns > 50)
ORDER BY 
    customer_value_segment, c.c_last_name, c.c_first_name
LIMIT 25 OFFSET 10;
