
WITH  sales_cte AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid) DESC) AS rank_paid
    FROM
        web_sales
    GROUP BY
        ws_bill_customer_sk
),
customer_returns AS (
    SELECT
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_returned_quantity,
        SUM(wr_return_amt) AS total_returned_amt
    FROM
        web_returns
    GROUP BY
        wr_returning_customer_sk
),
combined_sales AS (
    SELECT
        c.c_customer_sk,
        COALESCE(s.total_quantity, 0) AS total_quantity,
        COALESCE(s.total_net_paid, 0) AS total_net_paid,
        COALESCE(r.total_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(r.total_returned_amt, 0) AS total_returned_amt
    FROM
        customer c
    LEFT JOIN sales_cte s ON c.c_customer_sk = s.ws_bill_customer_sk
    LEFT JOIN customer_returns r ON c.c_customer_sk = r.wr_returning_customer_sk
)
SELECT
    ca.ca_city,
    COUNT(DISTINCT cs.c_customer_sk) AS number_of_customers,
    SUM(cs.total_quantity) AS total_quantity_sold,
    SUM(cs.total_net_paid) AS total_revenue,
    AVG(cs.total_net_paid) AS average_revenue_per_customer,
    SUM(cs.total_returned_quantity) AS total_returns,
    SUM(cs.total_returned_amt) AS total_returned_amount,
    CASE 
        WHEN SUM(cs.total_net_paid) > 0 THEN ROUND((SUM(cs.total_returned_amt) / SUM(cs.total_net_paid)) * 100, 2)
        ELSE 0
    END AS return_rate
FROM
    combined_sales cs
JOIN customer_address ca ON cs.c_customer_sk = ca.ca_address_sk
WHERE
    cs.total_net_paid > 100 AND
    cs.total_returned_amt IS NOT NULL
GROUP BY
    ca.ca_city
HAVING
    COUNT(DISTINCT cs.c_customer_sk) > 10
ORDER BY
    total_revenue DESC;
