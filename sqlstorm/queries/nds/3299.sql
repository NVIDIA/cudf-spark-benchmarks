
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        SUM(COALESCE(ws_quantity, 0) + COALESCE(cs_quantity, 0) + COALESCE(ss_quantity, 0)) AS total_quantity,
        COUNT(DISTINCT ws_order_number) AS web_order_count,
        COUNT(DISTINCT cs_order_number) AS catalog_order_count,
        COUNT(DISTINCT ss_ticket_number) AS store_order_count,
        cd_demo_sk,
        hd_income_band_sk
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    GROUP BY c.c_customer_sk, cd_demo_sk, hd_income_band_sk
),
RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        cs.total_quantity,
        cs.web_order_count,
        cs.catalog_order_count,
        cs.store_order_count,
        RANK() OVER (PARTITION BY cs.hd_income_band_sk ORDER BY cs.total_quantity DESC) AS income_rank
    FROM CustomerStats cs
    JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
),
TopCustomers AS (
    SELECT 
        rc.c_customer_sk,
        rc.total_quantity,
        rc.web_order_count,
        rc.catalog_order_count,
        rc.store_order_count
    FROM RankedCustomers rc
    WHERE rc.income_rank <= 5
)
SELECT 
    cu.c_customer_id,
    cu.c_first_name,
    cu.c_last_name,
    tc.total_quantity,
    tc.web_order_count,
    tc.catalog_order_count,
    tc.store_order_count,
    COALESCE(a.ca_city, 'Unknown') AS city,
    COALESCE(a.ca_state, 'Unknown') AS state
FROM TopCustomers tc
JOIN customer cu ON tc.c_customer_sk = cu.c_customer_sk
LEFT JOIN customer_address a ON cu.c_current_addr_sk = a.ca_address_sk
ORDER BY tc.total_quantity DESC
LIMIT 10;
