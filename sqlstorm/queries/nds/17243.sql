
SELECT
    ca_state,
    COUNT(DISTINCT c_customer_id) AS customer_count
FROM
    customer_address AS ca
JOIN
    customer AS c ON ca.ca_address_sk = c.c_current_addr_sk
GROUP BY
    ca_state
ORDER BY
    customer_count DESC
LIMIT 10;
