
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS rank_by_sales
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE c.c_birth_year BETWEEN 1980 AND 1990
    AND c.c_preferred_cust_flag = 'Y'
    GROUP BY ws.ws_item_sk
),
FilteredProducts AS (
    SELECT 
        i.i_item_sk,
        i.i_product_name,
        COALESCE((SELECT MAX(cr.cr_return_amount) 
                  FROM catalog_returns cr 
                  WHERE cr.cr_item_sk = i.i_item_sk), 0) AS max_return_amount
    FROM item i
    WHERE i.i_current_price + i.i_wholesale_cost > 100
    AND i.i_item_sk IN (SELECT ws_item_sk FROM RankedSales WHERE rank_by_sales = 1)
),
AddressCounts AS (
    SELECT 
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_id) AS customer_count
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE ca.ca_country = 'USA'
    GROUP BY ca.ca_state
)

SELECT 
    fp.i_product_name,
    fp.max_return_amount,
    ac.ca_state,
    ac.customer_count,
    CASE 
        WHEN ac.customer_count IS NULL THEN 'No Customers' 
        ELSE 'Customers Present' 
    END AS customer_status
FROM FilteredProducts fp
LEFT JOIN AddressCounts ac ON ac.customer_count > 0
WHERE fp.max_return_amount > 50
UNION ALL
SELECT 
    'Total',
    SUM(fp.max_return_amount),
    NULL,
    SUM(ac.customer_count),
    'Aggregate'
FROM FilteredProducts fp
JOIN AddressCounts ac ON ac.customer_count > 0
HAVING SUM(fp.max_return_amount) > 1000
ORDER BY 1, 4 DESC;
