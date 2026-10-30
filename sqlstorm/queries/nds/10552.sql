
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    COUNT(sr.sr_ticket_number) AS return_count,
    SUM(sr.sr_return_amt) AS total_return_amount
FROM
    customer c
LEFT JOIN
    store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
GROUP BY
    c.c_customer_id, c.c_first_name, c.c_last_name
ORDER BY
    return_count DESC
LIMIT 10;
