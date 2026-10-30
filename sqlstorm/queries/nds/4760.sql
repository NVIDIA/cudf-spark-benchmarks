
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt_inc_tax) AS total_returned_amt
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
HighSpendingCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year > 1980
    GROUP BY 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status
    HAVING 
        SUM(ws.ws_net_paid) > 1000
),
WarehouseStatistics AS (
    SELECT 
        w.w_warehouse_id, 
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        warehouse w
    JOIN 
        inventory inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    hsc.c_customer_sk,
    hsc.c_first_name,
    hsc.c_last_name,
    hsc.cd_gender,
    hsc.cd_marital_status,
    COALESCE(cr.total_returned_quantity, 0) AS total_returned_quantity,
    COALESCE(cr.total_returned_amt, 0) AS total_returned_amt,
    w.total_inventory
FROM 
    HighSpendingCustomers hsc
LEFT JOIN 
    CustomerReturns cr ON hsc.c_customer_sk = cr.sr_customer_sk
JOIN 
    WarehouseStatistics w ON w.total_inventory > 0
ORDER BY 
    hsc.total_spent DESC;
