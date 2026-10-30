
WITH CustomerReturns AS (
    SELECT
        sr_customer_sk,
        COUNT(DISTINCT sr_item_sk) AS unique_items_returned,
        SUM(sr_return_amt) AS total_return_amount,
        SUM(sr_return_quantity) AS total_return_quantity
    FROM
        store_returns
    GROUP BY
        sr_customer_sk
),
HighlyActiveCustomers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        COALESCE(cr.unique_items_returned, 0) AS unique_items_returned,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        COALESCE(cr.total_return_quantity, 0) AS total_return_quantity,
        cd.cd_gender,
        cd.cd_marital_status
    FROM
        customer c
    JOIN
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    WHERE
        cd.cd_purchase_estimate > 1000
        AND (cr.unique_items_returned IS NOT NULL OR cr.total_return_amount > 0)
),
CustomerSales AS (
    SELECT
        c.c_customer_sk,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY
        c.c_customer_sk
),
FinalReport AS (
    SELECT
        hac.c_customer_sk,
        hac.c_first_name,
        hac.c_last_name,
        hac.ca_city,
        hac.ca_state,
        sac.total_spent,
        sac.total_orders,
        hac.unique_items_returned,
        hac.total_return_amount,
        hac.total_return_quantity,
        hac.cd_gender,
        hac.cd_marital_status
    FROM
        HighlyActiveCustomers hac
    JOIN
        CustomerSales sac ON hac.c_customer_sk = sac.c_customer_sk
)
SELECT
    fr.c_customer_sk,
    fr.c_first_name,
    fr.c_last_name,
    fr.ca_city,
    fr.ca_state,
    fr.total_spent,
    fr.total_orders,
    fr.unique_items_returned,
    fr.total_return_amount,
    fr.total_return_quantity,
    fr.cd_gender,
    fr.cd_marital_status
FROM
    FinalReport fr
ORDER BY
    fr.total_spent DESC
LIMIT 100;
