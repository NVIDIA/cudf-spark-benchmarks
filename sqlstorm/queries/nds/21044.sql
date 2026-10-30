
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_quantity,
        ws_sales_price,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number DESC) AS SalesRank
    FROM web_sales
    WHERE ws_quantity > 0
),
AggregatedReturns AS (
    SELECT 
        cr_item_sk,
        SUM(cr_return_quantity) AS Total_Returns,
        SUM(cr_return_amount) AS Total_Return_Amount
    FROM catalog_returns
    GROUP BY cr_item_sk
),
FilteredAddresses AS (
    SELECT 
        ca_address_sk,
        ca_city,
        ca_state,
        CASE 
            WHEN ca_state IS NULL THEN 'Unknown'
            ELSE ca_state
        END AS State_Category
    FROM customer_address
    WHERE ca_city LIKE 'New%'
),
NullCheck AS (
    SELECT 
        DISTINCT c_customer_sk,
        c_first_name,
        c_last_name,
        CASE 
            WHEN c_birth_day IS NULL AND c_birth_month IS NULL 
                THEN 'Birthdate Unknown'
            ELSE CONCAT(COALESCE(CAST(c_birth_day AS STRING), '01'), '-', COALESCE(CAST(c_birth_month AS STRING), '01'))
        END AS Formatted_Birthdate
    FROM customer
)
SELECT 
    r.ws_item_sk,
    r.ws_order_number,
    r.ws_quantity,
    r.ws_sales_price,
    COALESCE(a.Total_Returns, 0) AS Total_Returns,
    COALESCE(a.Total_Return_Amount, 0) AS Total_Return_Amount,
    fa.ca_city,
    fa.State_Category,
    nc.c_first_name,
    nc.c_last_name,
    nc.Formatted_Birthdate
FROM RankedSales r
LEFT JOIN AggregatedReturns a ON r.ws_item_sk = a.cr_item_sk
LEFT JOIN FilteredAddresses fa ON fa.ca_address_sk = r.ws_order_number
LEFT JOIN NullCheck nc ON nc.c_customer_sk = r.ws_order_number
WHERE r.SalesRank = 1
AND (COALESCE(a.Total_Returns, 0) > 10 OR fa.ca_city IS NOT NULL)
ORDER BY r.ws_sales_price DESC, r.ws_item_sk ASC
LIMIT 100;
