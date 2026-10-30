WITH RankedReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        COUNT(sr_return_quantity) AS total_returns,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY COUNT(sr_return_quantity) DESC) AS rn
    FROM store_returns
    GROUP BY sr_returned_date_sk, sr_item_sk
),
Popularity AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sold,
        DENSE_RANK() OVER (ORDER BY SUM(ws_quantity) DESC) AS rank_sold
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 1 AND 30
    GROUP BY ws_item_sk
),
JoinedData AS (
    SELECT 
        ca_city, 
        ca_state,
        i_item_desc,
        COALESCE(r.total_returns, 0) AS total_returns,
        COALESCE(p.total_sold, 0) AS total_sold,
        CASE 
            WHEN COALESCE(p.total_sold, 0) = 0 THEN NULL 
            ELSE (COALESCE(r.total_returns, 0) * 1.0 / COALESCE(p.total_sold, 0)) 
        END AS return_rate
    FROM customer_address ca
    LEFT JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    LEFT JOIN item i ON i.i_item_sk = c.c_customer_sk % 1000 
    LEFT JOIN RankedReturns r ON r.sr_item_sk = i.i_item_sk
    LEFT JOIN Popularity p ON p.ws_item_sk = i.i_item_sk
    WHERE ca.ca_state = 'CA' AND (c.c_birth_year < 1980 OR c.c_birth_year IS NULL)
)
SELECT 
    ca_state,
    ca_city,
    AVG(return_rate) AS avg_return_rate,
    COUNT(DISTINCT i_item_desc) AS distinct_items,
    MAX(total_returns) AS max_returns,
    SUM(total_sold) AS total_sold_items
FROM JoinedData
WHERE return_rate IS NOT NULL
GROUP BY ca_state, ca_city
HAVING AVG(return_rate) > 0.1
ORDER BY avg_return_rate DESC, ca_city;