
WITH RankedReturns AS (
    SELECT
        sr_returned_date_sk,
        sr_item_sk,
        sr_return_quantity,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY sr_returned_date_sk DESC) AS return_rank
    FROM
        store_returns
    WHERE
        sr_return_quantity IS NOT NULL
),
SalesAggregate AS (
    SELECT
        ss_item_sk,
        SUM(ss_quantity) AS total_sold,
        AVG(ss_net_profit) AS avg_net_profit,
        COUNT(DISTINCT ss_ticket_number) AS num_sales
    FROM
        store_sales
    WHERE
        ss_sales_price > 20.00 AND ss_sold_date_sk BETWEEN 2459906 AND 2460557
    GROUP BY
        ss_item_sk
),
ShippingInfo AS (
    SELECT
        ws_item_sk,
        ws_net_paid,
        ws_net_paid_inc_ship_tax,
        COUNT(DISTINCT ws_order_number) AS order_count,
        MAX(ws_ship_mode_sk) AS max_ship_mode
    FROM
        web_sales
    WHERE
        ws_bill_customer_sk IS NOT NULL
    GROUP BY
        ws_item_sk, ws_net_paid, ws_net_paid_inc_ship_tax
),
CombinedResults AS (
    SELECT
        sa.ss_item_sk,
        sa.total_sold,
        sa.avg_net_profit,
        si.ws_net_paid,
        si.ws_net_paid_inc_ship_tax,
        si.order_count,
        COALESCE(r.return_rank, 0) AS return_count
    FROM
        SalesAggregate sa
    LEFT JOIN
        ShippingInfo si ON sa.ss_item_sk = si.ws_item_sk
    LEFT JOIN
        RankedReturns r ON sa.ss_item_sk = r.sr_item_sk
    WHERE
        sa.num_sales > 5 AND (si.ws_net_paid > 100 OR si.ws_net_paid_inc_ship_tax > 150)
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cr.return_count,
    cr.total_sold,
    cr.avg_net_profit,
    CASE
        WHEN cr.order_count > 10 THEN 'Frequent Buyer'
        WHEN cr.order_count BETWEEN 5 AND 10 THEN 'Occasional Buyer'
        ELSE 'Rare Buyer'
    END AS buyer_type,
    c.c_birth_year IS NULL AS null_birth_year
FROM
    customer c
LEFT JOIN
    CombinedResults cr ON c.c_customer_sk = cr.ss_item_sk
WHERE
    (c.c_preferred_cust_flag = 'Y' OR c.c_login LIKE '%@example.com')
    AND (c.c_birth_month = 12 OR (c.c_birth_month IS NULL AND cr.total_sold > 0));
