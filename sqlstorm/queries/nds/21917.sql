
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_paid DESC) AS rnk,
        CASE 
            WHEN ws.ws_net_paid > 1000 THEN 'High'
            WHEN ws.ws_net_paid BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS sales_category
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
customer_return_data AS (
    SELECT 
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_order_number,
        cr.cr_item_sk
    FROM 
        catalog_returns cr 
    WHERE 
        cr.cr_return_quantity IS NOT NULL AND 
        cr.cr_return_quantity > 0
),
combined_sales AS (
    SELECT 
        r.ws_item_sk,
        r.ws_order_number,
        r.ws_sales_price,
        r.sales_category,
        COALESCE(ret.cr_return_quantity, 0) AS returned_quantity,
        COALESCE(ret.cr_return_amount, 0) AS return_amount
    FROM 
        ranked_sales r
    LEFT JOIN 
        customer_return_data ret 
    ON 
        r.ws_order_number = ret.cr_order_number 
        AND r.ws_item_sk = ret.cr_item_sk
)
SELECT 
    cs.ws_item_sk,
    cs.sales_category,
    SUM(cs.ws_sales_price) AS total_sales,
    AVG(cs.return_amount) AS avg_return_amount,
    COUNT(CASE WHEN cs.returned_quantity > 0 THEN 1 END) AS number_of_returns,
    CASE 
        WHEN AVG(cs.ws_sales_price) IS NULL THEN 'No Sales' 
        WHEN AVG(cs.return_amount) IS NOT NULL THEN 'Returns Present' 
        ELSE 'Sales Only' 
    END AS sales_return_status
FROM 
    combined_sales cs
JOIN 
    customer_demographics cd ON cs.ws_item_sk = cd.cd_demo_sk
WHERE 
    cd.cd_gender = 'M'
GROUP BY 
    cs.ws_item_sk, cs.sales_category
HAVING 
    SUM(cs.ws_sales_price) > 500
ORDER BY 
    total_sales DESC, 
    cs.ws_item_sk ASC
LIMIT 10;
