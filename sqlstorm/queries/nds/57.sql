
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk, 
        SUM(sr_return_amt) AS total_return_amt,
        COUNT(DISTINCT sr_ticket_number) AS total_returns
    FROM store_returns
    WHERE sr_return_quantity > 0
    GROUP BY sr_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name,
        cr.total_return_amt,
        cr.total_returns,
        ROW_NUMBER() OVER (ORDER BY cr.total_return_amt DESC) AS rn
    FROM customer c
    JOIN CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    WHERE c.c_birth_year < 1980 AND c.c_preferred_cust_flag = 'Y'
),
HighIncomeDemographics AS (
    SELECT 
        h.hd_demo_sk, 
        h.hd_income_band_sk, 
        h.hd_buy_potential,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM household_demographics h
    JOIN income_band ib ON h.hd_income_band_sk = ib.ib_income_band_sk
    WHERE h.hd_buy_potential = 'High'
),
WarehouseInventory AS (
    SELECT 
        inv.inv_warehouse_sk, 
        SUM(inv.inv_quantity_on_hand) AS total_quantity
    FROM inventory inv
    GROUP BY inv.inv_warehouse_sk
)
SELECT 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    hid.hd_income_band_sk,
    hid.ib_lower_bound,
    hid.ib_upper_bound,
    wi.total_quantity,
    tc.total_return_amt,
    tc.total_returns
FROM TopCustomers tc
LEFT JOIN HighIncomeDemographics hid ON tc.c_customer_id = CAST(hid.hd_demo_sk AS STRING)
FULL OUTER JOIN WarehouseInventory wi ON wi.inv_warehouse_sk IS NOT NULL
WHERE (wi.total_quantity > 100 OR tc.total_returns > 5)
AND (tc.rn <= 10 OR wi.total_quantity IS NULL)
ORDER BY tc.total_return_amt DESC, wi.total_quantity ASC;
