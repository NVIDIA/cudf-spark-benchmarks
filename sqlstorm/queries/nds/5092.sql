
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ss.ss_net_paid) AS total_spent,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ss.ss_net_paid) DESC) AS gender_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE ss.ss_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim) - 30 
                                  AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
CustomerAddresses AS (
    SELECT 
        ca.ca_address_id,
        ca.ca_city,
        ca.ca_state,
        rc.c_customer_id,
        rc.total_spent
    FROM RankedCustomers rc
    JOIN customer_address ca ON rc.c_customer_id = ca.ca_address_id
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT rc.c_customer_id) AS customer_count,
    AVG(rc.total_spent) AS average_spent,
    MAX(rc.total_spent) AS max_spent
FROM CustomerAddresses ca
JOIN RankedCustomers rc ON ca.c_customer_id = rc.c_customer_id
GROUP BY ca.ca_city, ca.ca_state
ORDER BY customer_count DESC
LIMIT 10;
