
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_ext_sales_price) AS total_spent,
        MAX(ws.ws_sold_date_sk) AS last_purchase_date
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
),
IncomeBandStats AS (
    SELECT 
        h.hd_demo_sk,
        IB.ib_income_band_sk,
        CASE 
            WHEN IB.ib_lower_bound <= 20000 THEN 'Low'
            WHEN IB.ib_lower_bound BETWEEN 20001 AND 60000 THEN 'Medium'
            ELSE 'High'
        END AS income_band
    FROM household_demographics h
    JOIN income_band IB ON h.hd_income_band_sk = IB.ib_income_band_sk
),
SalesData AS (
    SELECT 
        ss.ss_item_sk,
        SUM(ss.ss_quantity) AS total_quantity_sold,
        SUM(ss.ss_net_profit) AS total_net_profit
    FROM store_sales ss
    GROUP BY ss.ss_item_sk
)
SELECT 
    cs.c_first_name, 
    cs.c_last_name,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.total_spent,
    COALESCE(ibs.income_band, 'Unknown') AS income_band,
    COALESCE(sd.total_quantity_sold, 0) AS total_quantity_sold,
    COALESCE(sd.total_net_profit, 0) AS total_net_profit
FROM CustomerStats cs
LEFT JOIN IncomeBandStats ibs ON cs.c_customer_sk = ibs.hd_demo_sk
LEFT JOIN SalesData sd ON cs.c_customer_sk = sd.ss_item_sk
WHERE cs.order_count > 0
AND (cs.total_spent > 100 OR sd.total_net_profit > 500)
ORDER BY cs.last_purchase_date DESC, cs.total_spent DESC
LIMIT 100;
