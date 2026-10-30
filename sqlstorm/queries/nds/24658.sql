
WITH RankedStores AS (
    SELECT 
        s_store_sk,
        s_store_id,
        s_store_name,
        ROW_NUMBER() OVER (PARTITION BY s_state ORDER BY s_floor_space DESC) AS rn
    FROM 
        store
    WHERE 
        s_closed_date_sk IS NULL
),
CustomerPurchases AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ss_ticket_number) AS total_purchases,
        SUM(ss_net_profit) AS total_net_profit
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk
),
HighValueCustomers AS (
    SELECT 
        cp.c_customer_sk,
        cp.total_purchases,
        cp.total_net_profit
    FROM 
        CustomerPurchases cp
    WHERE 
        cp.total_net_profit > (
            SELECT 
                AVG(total_net_profit)
            FROM 
                CustomerPurchases
            WHERE 
                total_purchases > 0
        )
),
ReturnStats AS (
    SELECT 
        sr_cdemo_sk, 
        COUNT(*) AS return_count,
        SUM(sr_return_amt_inc_tax) AS total_returned
    FROM 
        store_returns
    GROUP BY 
        sr_cdemo_sk
),
CustomerReturnRate AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(r.return_count, 0) AS return_count,
        COALESCE(r.total_returned, 0) AS total_returned,
        CASE 
            WHEN cp.total_purchases > 0 THEN 
                COALESCE(r.return_count, 0) * 1.0 / cp.total_purchases 
            ELSE 0 
        END AS return_rate
    FROM 
        customer c
    LEFT JOIN 
        ReturnStats r ON c.c_customer_sk = r.sr_cdemo_sk
    LEFT JOIN 
        CustomerPurchases cp ON c.c_customer_sk = cp.c_customer_sk
),
OverallStats AS (
    SELECT 
        cu.c_customer_sk,
        ic.ib_income_band_sk,
        CU.total_net_profit,
        COALESCE(CRR.return_rate, 0) AS return_rate
    FROM 
        HighValueCustomers cu
    LEFT JOIN 
        household_demographics h ON cu.c_customer_sk = h.hd_demo_sk
    LEFT JOIN 
        income_band ic ON h.hd_income_band_sk = ic.ib_income_band_sk
    LEFT JOIN 
        CustomerReturnRate CRR ON cu.c_customer_sk = CRR.c_customer_sk
)
SELECT 
    os.c_customer_sk,
    os.ib_income_band_sk,
    CASE 
        WHEN os.return_rate < 0.1 THEN 'Low Return Rate'
        WHEN os.return_rate BETWEEN 0.1 AND 0.5 THEN 'Moderate Return Rate'
        ELSE 'High Return Rate'
    END AS return_label,
    SUM(ws.ws_net_profit) OVER (PARTITION BY os.ib_income_band_sk) AS income_band_profit
FROM 
    OverallStats os
JOIN 
    web_sales ws ON os.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    os.return_rate IS NOT NULL
    AND os.return_rate < 1.0
    AND EXISTS (
        SELECT 1
        FROM RankedStores rs
        WHERE rs.rn = 1 AND rs.s_store_sk = ws.ws_ship_mode_sk
    )
ORDER BY 
    os.ib_income_band_sk;
