
WITH  sales_data AS (
    SELECT
        ds.d_year,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM
        date_dim ds
    JOIN
        web_sales ws ON ds.d_date_sk = ws.ws_sold_date_sk
    WHERE
        ds.d_year BETWEEN 2010 AND 2022
    GROUP BY
        ds.d_year
),
customer_stats AS (
    SELECT
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM
        customer c
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY
        ca.ca_state
),
return_data AS (
    SELECT
        sr_returned_date_sk,
        SUM(sr_return_amt) AS total_return_amount,
        COUNT(sr_ticket_number) AS total_returns
    FROM
        store_returns
    GROUP BY
        sr_returned_date_sk
)
SELECT
    sd.d_year,
    cs.ca_state,
    cs.unique_customers,
    cs.avg_purchase_estimate,
    COALESCE(sd.total_sales, 0) AS total_sales,
    COALESCE(rd.total_return_amount, 0) AS total_return_amount,
    COALESCE(rd.total_returns, 0) AS total_returns
FROM
    sales_data sd
FULL OUTER JOIN
    customer_stats cs ON cs.ca_state IS NOT NULL
LEFT JOIN
    return_data rd ON rd.sr_returned_date_sk = sd.d_year
WHERE
    (cs.avg_purchase_estimate IS NOT NULL OR COALESCE(sd.total_sales, 0) > 10000)
ORDER BY
    sd.d_year DESC, cs.ca_state;
