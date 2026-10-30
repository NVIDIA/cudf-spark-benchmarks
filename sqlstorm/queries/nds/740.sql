
WITH RankedSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_order_number,
        ws_quantity,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS sales_rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN (
        SELECT MAX(d_date_sk) 
        FROM date_dim 
        WHERE d_year = 2023) - 30 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM customer c
    JOIN customer_demographics cd 
        ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate > 500
),
SalesSummary AS (
    SELECT 
        r.ws_order_number,
        SUM(r.ws_quantity * r.ws_sales_price) AS total_sales,
        COUNT(DISTINCT c.c_customer_id) AS unique_customers
    FROM RankedSales r
    JOIN CustomerInfo c 
        ON r.ws_order_number = c.c_customer_sk
    GROUP BY r.ws_order_number
)
SELECT 
    ss.ws_order_number,
    ss.total_sales,
    ss.unique_customers,
    CASE 
        WHEN ss.total_sales IS NULL THEN 'No Sales'
        ELSE 
            CASE 
                WHEN ss.total_sales < 1000 THEN 'Low Sales'
                WHEN ss.total_sales BETWEEN 1000 AND 5000 THEN 'Moderate Sales'
                ELSE 'High Sales'
            END 
    END AS sales_category
FROM SalesSummary ss
LEFT JOIN (
    SELECT 
        DISTINCT ws_order_number 
    FROM web_sales 
    WHERE ws_ship_mode_sk IN (SELECT sm_ship_mode_sk FROM ship_mode WHERE sm_carrier = 'FedEx')
) FedExOrders ON ss.ws_order_number = FedExOrders.ws_order_number
WHERE ss.unique_customers > 5
ORDER BY ss.total_sales DESC;
