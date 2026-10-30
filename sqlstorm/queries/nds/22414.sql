
WITH CustomerReturns AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(sr_return_quantity, 0)) AS total_returns,
        COUNT(DISTINCT sr_ticket_number) AS unique_returns
    FROM
        customer c
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
RankedReturns AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cr.total_returns,
        cr.unique_returns,
        RANK() OVER (ORDER BY cr.total_returns DESC) AS return_rank
    FROM
        CustomerReturns cr
    JOIN customer c ON cr.c_customer_sk = c.c_customer_sk
),
ReturnDetails AS (
    SELECT
        r.c_customer_sk,
        r.c_first_name,
        r.c_last_name,
        COALESCE(r.total_returns, 0) AS total_returns,
        o.ws_sales_price,
        o.ws_quantity,
        o.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY r.c_customer_sk ORDER BY o.ws_sales_price DESC) AS sales_rank
    FROM
        RankedReturns r
    LEFT JOIN web_sales o ON r.c_customer_sk = o.ws_bill_customer_sk
    WHERE
        o.ws_sales_price IS NOT NULL
        AND o.ws_net_profit IS NOT NULL
        AND (r.total_returns > 0 OR (o.ws_quantity > 5 AND r.c_customer_sk IS NOT NULL))
)
SELECT
    rd.c_customer_sk,
    rd.c_first_name,
    rd.c_last_name,
    rd.total_returns,
    SUM(CASE WHEN rd.sales_rank <= 3 THEN rd.ws_sales_price END) AS top_sales_price_sum,
    AVG(rd.ws_net_profit) AS avg_net_profit,
    COUNT(DISTINCT o.ws_order_number) AS total_orders,
    MAX(rd.ws_sales_price) AS max_sales_price
FROM
    ReturnDetails rd
LEFT JOIN web_sales o ON rd.c_customer_sk = o.ws_bill_customer_sk
GROUP BY
    rd.c_customer_sk, rd.c_first_name, rd.c_last_name, rd.total_returns
HAVING
    (rd.total_returns > 0 AND COUNT(o.ws_order_number) > 1)
    OR (rd.total_returns IS NULL AND MAX(rd.ws_sales_price) > 100.00)
ORDER BY
    avg_net_profit DESC,
    total_returns DESC;
