
WITH CustomerReturns AS (
    SELECT
        sr_customer_sk,
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        SUM(sr_return_quantity) AS total_return_quantity
    FROM
        store_returns
    GROUP BY
        sr_customer_sk
),
TopCustomers AS (
    SELECT
        cr.sr_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cr.total_returns,
        cr.total_return_amount,
        cr.total_return_quantity,
        RANK() OVER (ORDER BY cr.total_return_amount DESC) AS rank
    FROM
        CustomerReturns cr
    JOIN
        customer c ON cr.sr_customer_sk = c.c_customer_sk
    WHERE
        cr.total_returns > 0
),
InventorySummary AS (
    SELECT
        inv.inv_warehouse_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory,
        COUNT(DISTINCT inv.inv_item_sk) AS distinct_items
    FROM
        inventory inv
    GROUP BY
        inv.inv_warehouse_sk
)
SELECT
    tc.sr_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_returns,
    tc.total_return_amount,
    tc.total_return_quantity,
    ws.w_warehouse_id,
    ws.w_warehouse_name,
    isys.total_inventory,
    isys.distinct_items
FROM
    TopCustomers tc
LEFT JOIN
    warehouse ws ON ws.w_warehouse_sk IN (
        SELECT inv.inv_warehouse_sk
        FROM inventory inv
        WHERE inv.inv_quantity_on_hand < 5
        GROUP BY inv.inv_warehouse_sk
    )
JOIN
    InventorySummary isys ON isys.inv_warehouse_sk = ws.w_warehouse_sk
WHERE 
    tc.rank <= 10
ORDER BY 
    tc.total_return_amount DESC, 
    tc.c_last_name ASC;
