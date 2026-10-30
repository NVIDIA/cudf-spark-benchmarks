WITH CustomerReturnStats AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        AVG(sr_return_quantity) AS avg_return_quantity,
        ROW_NUMBER() OVER (ORDER BY SUM(sr_return_amt_inc_tax) DESC) AS return_rank
    FROM customer c
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighReturnCustomers AS (
    SELECT *
    FROM CustomerReturnStats
    WHERE total_returns > 5
)
SELECT
    CONCAT(h.c_first_name, ' ', h.c_last_name) AS customer_name,
    h.total_returns,
    h.total_return_amount,
    h.avg_return_quantity,
    CASE 
        WHEN h.total_return_amount > 1000 THEN 'High Value'
        ELSE 'Standard Value'
    END AS customer_value_category
FROM HighReturnCustomers h
INNER JOIN customer_demographics cd ON h.c_customer_sk = cd.cd_demo_sk
WHERE cd.cd_gender = 'F'
  AND cd.cd_marital_status = 'M'
  AND EXISTS (
      SELECT 1
      FROM web_sales ws
      WHERE ws.ws_bill_customer_sk = h.c_customer_sk
        AND ws.ws_sold_date_sk = (
            SELECT MAX(d.d_date_sk)
            FROM date_dim d
            WHERE d.d_date < cast('2002-10-01' as date)
        )
  )
ORDER BY h.total_return_amount DESC
LIMIT 10;