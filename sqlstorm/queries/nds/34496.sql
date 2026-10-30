
WITH  SalesCTE AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        ws_quantity, 
        ws_net_paid,
        ROW_NUMBER() OVER(PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
),
RecentSales AS (
    SELECT 
        s.ws_item_sk,
        SUM(s.ws_quantity) AS total_quantity,
        SUM(s.ws_net_paid) AS total_net_paid,
        COALESCE(MAX(s.ws_sold_date_sk), 0) AS last_sold_date
    FROM 
        SalesCTE s
    JOIN 
        item i ON s.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price IS NOT NULL 
        AND (EXISTS (SELECT 1 FROM store_sales WHERE ss_item_sk = s.ws_item_sk)
             OR EXISTS (SELECT 1 FROM catalog_sales WHERE cs_item_sk = s.ws_item_sk))
    GROUP BY 
        s.ws_item_sk
)
SELECT 
    i.i_item_id,
    r.total_quantity,
    r.total_net_paid,
    d.d_date AS last_sales_date,
    i.i_current_price * r.total_quantity AS total_revenue,
    CASE 
        WHEN r.total_quantity > 0 THEN 'Positive Sales'
        ELSE 'No Sales'
    END AS sales_status,
    STRING_AGG(DISTINCT CONCAT(c.c_first_name, ' ', c.c_last_name), ', ') AS customer_names
FROM 
    RecentSales r
JOIN 
    item i ON r.ws_item_sk = i.i_item_sk
LEFT JOIN 
    web_sales ws ON i.i_item_sk = ws.ws_item_sk
LEFT JOIN 
    customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
LEFT JOIN 
    date_dim d ON r.last_sold_date = d.d_date_sk
WHERE 
    r.total_net_paid >= 1000
    AND r.total_quantity > (SELECT AVG(total_quantity) FROM RecentSales)
GROUP BY 
    i.i_item_id, r.total_quantity, r.total_net_paid, d.d_date, i.i_current_price
HAVING 
    COUNT(c.c_customer_sk) > 10
ORDER BY 
    total_revenue DESC;
