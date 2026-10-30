
WITH Address_Counts AS (
    SELECT ca_state, COUNT(*) AS address_count
    FROM customer_address
    GROUP BY ca_state
),
Customer_Demographics AS (
    SELECT cd_gender, COUNT(*) AS demographic_count
    FROM customer_demographics
    GROUP BY cd_gender
),
Sales_Data AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales ws
    WHERE ws.ws_sales_price > 100
    GROUP BY ws.ws_item_sk
)
SELECT
    a.ca_state,
    a.address_count,
    d.cd_gender,
    d.demographic_count,
    s.total_sales,
    s.total_quantity,
    s.order_count
FROM Address_Counts a
JOIN Customer_Demographics d ON d.demographic_count > 0
LEFT JOIN Sales_Data s ON s.ws_item_sk IN (SELECT i_item_sk FROM item WHERE i_category = 'Beverages')
WHERE a.address_count > 100
ORDER BY a.ca_state, d.cd_gender;
