
SELECT
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    COUNT(sr.sr_ticket_number) AS total_returns,
    SUM(sr.sr_return_amt_inc_tax) AS total_return_value
FROM
    customer AS c
LEFT JOIN
    store_returns AS sr ON c.c_customer_sk = sr.sr_customer_sk
GROUP BY
    c.c_customer_sk, c.c_first_name, c.c_last_name
ORDER BY
    total_returns DESC
LIMIT 100;
