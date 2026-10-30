
WITH RankedReturns AS (
    SELECT
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned,
        COUNT(DISTINCT sr_ticket_number) AS return_transactions,
        DENSE_RANK() OVER (PARTITION BY sr_item_sk ORDER BY SUM(sr_return_quantity) DESC) AS rank
    FROM
        store_returns
    GROUP BY
        sr_item_sk
),
CustomerReturns AS (
    SELECT
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_customer_returns,
        AVG(sr_return_amt) AS avg_return_amount,
        COUNT(DISTINCT sr_item_sk) AS unique_items_returned
    FROM
        store_returns
    WHERE
        sr_return_quantity > 0
    GROUP BY
        sr_customer_sk
),
TopReturnItems AS (
    SELECT
        rr.sr_item_sk,
        rr.total_returned,
        rr.return_transactions
    FROM
        RankedReturns rr
    WHERE
        rr.rank <= 5
)
SELECT DISTINCT
    ca.ca_address_id,
    cd.cd_gender,
    SUM(ws.ws_quantity) AS total_sales,
    COUNT(DISTINCT ws.ws_order_number) AS unique_orders,
    (SELECT COUNT(*) FROM CustomerReturns cr WHERE cr.total_customer_returns > 5) AS high_return_customers,
    MAX(CASE WHEN wr_return_amt IS NULL THEN 0 ELSE wr_return_amt END) AS max_web_return_amt,
    COALESCE(MAX(sm.sm_carrier), 'Unknown') AS carrier_or_unknown,
    COUNT(DISTINCT CASE WHEN cs.cs_item_sk IN (SELECT ti.sr_item_sk FROM TopReturnItems ti) THEN cs.cs_order_number END) AS orders_with_top_return_items
FROM
    customer_address ca
    JOIN customer_demographics cd ON ca.ca_address_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON ws.ws_bill_addr_sk = ca.ca_address_sk
    LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
    LEFT JOIN catalog_sales cs ON cs.cs_bill_addr_sk = ca.ca_address_sk
    LEFT JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE
    (cd.cd_marital_status = 'M' OR cd.cd_gender = 'F')
    AND (CAST(ca.ca_zip AS INTEGER) IS NOT NULL OR ca.ca_city IS NOT NULL)
    AND (EXISTS (
        SELECT 1
        FROM inventory inv
        WHERE inv.inv_quantity_on_hand < 100
        AND inv.inv_item_sk = ws.ws_item_sk
    ) OR ws.ws_sold_date_sk IN (
        SELECT DISTINCT d.d_date_sk
        FROM date_dim d
        WHERE d.d_year = 2023 AND d.d_weekend = 'Y'
    ))
GROUP BY
    ca.ca_address_id, cd.cd_gender
HAVING
    SUM(ws.ws_quantity) > 500
    OR COUNT(DISTINCT ws.ws_order_number) > 10
ORDER BY
    total_sales DESC, unique_orders ASC
LIMIT 100;
