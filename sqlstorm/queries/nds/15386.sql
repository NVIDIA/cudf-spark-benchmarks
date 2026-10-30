
SELECT
    c.c_customer_id,
    COUNT(sr.sr_item_sk) AS total_returns
FROM
    customer c
JOIN
    store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
GROUP BY
    c.c_customer_id
ORDER BY
    total_returns DESC
LIMIT 10;
