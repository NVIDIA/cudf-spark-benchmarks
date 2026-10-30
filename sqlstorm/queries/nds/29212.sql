
WITH CustomerDetails AS (
    SELECT 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        COUNT(DISTINCT sr.sr_item_sk) AS total_returns,
        SUM(sr.sr_return_amt) AS total_return_amount
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    WHERE cd.cd_gender IN ('M', 'F')
    GROUP BY c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state, cd.cd_gender
),
ReturnStats AS (
    SELECT 
        ca_state,
        cd_gender,
        AVG(total_returns) AS avg_returns,
        SUM(total_return_amount) AS total_return_volume
    FROM CustomerDetails
    GROUP BY ca_state, cd_gender
)
SELECT 
    r.ca_state,
    r.cd_gender,
    r.avg_returns,
    r.total_return_volume,
    CASE 
        WHEN r.avg_returns > 10 THEN 'High Return'
        WHEN r.avg_returns BETWEEN 5 AND 10 THEN 'Moderate Return'
        ELSE 'Low Return'
    END AS return_category
FROM ReturnStats r
ORDER BY r.ca_state, r.cd_gender;
