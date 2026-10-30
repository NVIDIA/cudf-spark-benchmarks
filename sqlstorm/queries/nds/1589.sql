
WITH SalesData AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk
),
CustomerStats AS (
    SELECT 
        c_customer_sk,
        cd_gender,
        cd_marital_status,
        COALESCE(hd_income_band_sk, -1) AS income_band,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_profit) AS total_spent
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c_customer_sk, cd_gender, cd_marital_status, hd_income_band_sk
),
TopSellingItems AS (
    SELECT 
        sd.ws_item_sk,
        ROW_NUMBER() OVER (ORDER BY SUM(sd.total_profit) DESC) AS rank
    FROM SalesData sd
    GROUP BY sd.ws_item_sk
    HAVING SUM(sd.total_profit) > 5000
)
SELECT 
    cs.c_customer_sk,
    cs.cd_gender,
    cs.cd_marital_status,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    cs.total_orders,
    cs.total_spent,
    COALESCE(tsi.rank, 0) AS item_rank
FROM CustomerStats cs
LEFT JOIN income_band ib ON cs.income_band = ib.ib_income_band_sk
LEFT JOIN TopSellingItems tsi ON cs.total_orders > 5 AND cs.total_spent > 1000
WHERE (cs.cd_gender = 'M' AND cs.total_spent > 5000)
   OR (cs.cd_gender = 'F' AND cs.total_orders > 10)
ORDER BY cs.total_spent DESC, cs.total_orders DESC;
