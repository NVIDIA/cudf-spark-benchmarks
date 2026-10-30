WITH RankedSales AS (
    SELECT 
        ss_store_sk, 
        SUM(ss_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_sales_price) DESC) AS sales_rank
    FROM store_sales
    WHERE ss_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2001) - 30
    GROUP BY ss_store_sk
),
CustomerStats AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_paid) AS total_spent
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
SalesData AS (
    SELECT 
        ws.ws_ship_mode_sk,
        sm.sm_type,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY ws.ws_ship_mode_sk, sm.sm_type
),
ReturnData AS (
    SELECT 
        sr_returned_date_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount
    FROM store_returns
    GROUP BY sr_returned_date_sk
)
SELECT 
    s.s_store_id,
    s.s_store_name,
    r.total_sales,
    cs.total_orders,
    cs.total_spent,
    sd.total_profit,
    COALESCE(rd.total_returns, 0) AS total_returns,
    CASE 
        WHEN cs.total_spent > 1000 THEN 'High Spending'
        WHEN cs.total_spent BETWEEN 500 AND 1000 THEN 'Medium Spending'
        ELSE 'Low Spending'
    END AS spending_category
FROM store s
LEFT JOIN RankedSales r ON s.s_store_sk = r.ss_store_sk
LEFT JOIN CustomerStats cs ON cs.c_customer_id = 'CUST001'  
LEFT JOIN SalesData sd ON s.s_store_sk = sd.ws_ship_mode_sk
LEFT JOIN ReturnData rd ON rd.sr_returned_date_sk = (SELECT MAX(d_date_sk) FROM date_dim)
WHERE r.sales_rank = 1
ORDER BY total_sales DESC, total_spent DESC;