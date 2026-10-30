
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        ws.ws_ext_tax,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rank_sales
    FROM web_sales ws
    WHERE ws.ws_sales_price IS NOT NULL
), FilteredReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned,
        SUM(sr_return_amt) AS total_return_amount
    FROM store_returns
    GROUP BY sr_item_sk
    HAVING SUM(sr_return_quantity) > 0
), DailySales AS (
    SELECT 
        d.d_date AS sale_date,
        SUM(cs.cs_quantity) AS total_quantity_sold,
        COUNT(DISTINCT cs.cs_order_number) AS total_orders
    FROM date_dim d
    JOIN catalog_sales cs ON d.d_date_sk = cs.cs_sold_date_sk
    WHERE d.d_year = 2023
    GROUP BY d.d_date
), CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate
    FROM customer_demographics
    WHERE cd_purchase_estimate IS NOT NULL
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT c.c_customer_sk) AS total_customers,
    SUM(COALESCE(r.total_returned, 0)) AS total_returns,
    SUM(COALESCE(rs.ws_ext_sales_price, 0)) AS total_sales,
    AVG(d.total_orders) AS avg_orders_per_day,
    MIN(COALESCE(c.c_birth_year, 1900)) AS earliest_birth_year,
    MAX(d.sale_date) AS last_sale_date
FROM customer c
LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN FilteredReturns r ON r.sr_item_sk = c.c_customer_sk
LEFT JOIN RankedSales rs ON rs.ws_order_number = c.c_customer_sk
LEFT JOIN DailySales d ON d.sale_date = CURRENT_DATE - INTERVAL '1 day'
WHERE ca.ca_state IS NOT NULL
GROUP BY ca.ca_city, ca.ca_state
HAVING COUNT(DISTINCT c.c_customer_sk) > 10
ORDER BY total_sales DESC, total_returns ASC
LIMIT 50;
