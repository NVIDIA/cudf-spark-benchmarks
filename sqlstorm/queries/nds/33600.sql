
WITH  Sales_CTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price * ws_quantity) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price * ws_quantity) DESC) AS sales_rank
    FROM web_sales
    WHERE ws_ship_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_item_sk
),
Filtered_Items AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        COALESCE(si.total_sales, 0) AS total_sales
    FROM item i
    LEFT JOIN Sales_CTE si ON i.i_item_sk = si.ws_item_sk
),
Address_CTE AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM customer_address ca
    JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY ca.ca_address_sk, ca.ca_city, ca.ca_state
),
Top_Cities AS (
    SELECT 
        a.ca_city,
        a.ca_state,
        SUM(a.customer_count) AS total_customers
    FROM Address_CTE a
    GROUP BY a.ca_city, a.ca_state
    ORDER BY total_customers DESC
    LIMIT 10
)
SELECT 
    fi.i_item_desc,
    fi.total_sales,
    tc.ca_city,
    tc.total_customers
FROM Filtered_Items fi
JOIN Top_Cities tc ON fi.total_sales > 0
WHERE fi.total_sales IS NOT NULL
ORDER BY fi.total_sales DESC;
