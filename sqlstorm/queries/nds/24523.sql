
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_quantity DESC) AS quantity_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) - 30 FROM date_dim d WHERE d.d_current_month = '1')
),
AggregateReturns AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returned,
        COUNT(DISTINCT cr.cr_order_number) AS total_orders
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.cr_item_sk
),
FilteredCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        cd.cd_gender,
        CASE 
            WHEN cd.cd_purchase_estimate > 1000 THEN 'High Value'
            WHEN cd.cd_purchase_estimate BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender IS NOT NULL AND cd.cd_marital_status IS NOT NULL
)
SELECT 
    fc.c_first_name,
    fc.c_last_name,
    fr.total_returned,
    avg(r.ws_sales_price) AS average_sales_price,
    SUM(CASE WHEN fr.total_orders > 0 THEN 1 ELSE 0 END) AS order_count
FROM 
    FilteredCustomers fc
LEFT JOIN 
    AggregateReturns fr ON fc.c_customer_sk = fr.cr_item_sk
JOIN 
    web_sales r ON r.ws_item_sk = fr.cr_item_sk 
WHERE 
    r.ws_quantity > 0 AND 
    (SELECT COUNT(*) FROM RankedSales rs WHERE rs.ws_item_sk = r.ws_item_sk AND rs.price_rank = 1) > 0
GROUP BY 
    fc.c_first_name, 
    fc.c_last_name, 
    fr.total_returned
HAVING 
    COALESCE(fr.total_returned, 0) > 0 AND 
    COUNT(r.ws_order_number) > 3
ORDER BY 
    average_sales_price DESC
LIMIT 10;
