
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        SUM(ws.ws_net_paid) AS total_spent,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_paid) DESC) AS rank,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
TopCustomers AS (
    SELECT * 
    FROM RankedCustomers 
    WHERE rank <= 5
),
MaxSpendByGender AS (
    SELECT 
        cd.cd_gender, 
        MAX(total_spent) AS max_spent 
    FROM RankedCustomers rc
    JOIN customer_demographics cd ON rc.c_customer_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender
),
RevenueAndReturns AS (
    SELECT 
        w.w_warehouse_id, 
        COALESCE(SUM(ws.ws_ext_sales_price), 0) AS total_revenue,
        COALESCE(SUM(sr.sr_return_amt), 0) AS total_returns,
        COALESCE(SUM(sr.sr_return_quantity), 0) AS total_returned_items,
        COALESCE(MAX(rt.r_reason_desc), 'No Returns') AS last_return_reason
    FROM warehouse w
    LEFT JOIN web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    LEFT JOIN store_returns sr ON ws.ws_item_sk = sr.sr_item_sk
    LEFT JOIN reason rt ON sr.sr_reason_sk = rt.r_reason_sk
    GROUP BY w.w_warehouse_id
),
FinalReport AS (
    SELECT 
        tc.c_first_name, 
        tc.c_last_name, 
        tc.total_spent, 
        tc.order_count,
        r.total_revenue,
        r.total_returns,
        r.total_returned_items,
        r.last_return_reason,
        mbg.max_spent AS gender_max_spent
    FROM TopCustomers tc
    CROSS JOIN RevenueAndReturns r
    JOIN MaxSpendByGender mbg ON (tc.cd_gender = mbg.cd_gender)
)
SELECT 
    *, 
    CASE 
        WHEN total_spent > gender_max_spent THEN 'Exceeded Max Spend'
        ELSE 'Within Limit'
    END AS spend_comparison
FROM FinalReport
WHERE total_returns < total_revenue / NULLIF(total_spent, 0)
ORDER BY total_spent DESC, order_count ASC;
