
WITH CustomerPerformance AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        cd.cd_gender,
        MAX(ws.ws_net_profit) AS max_net_profit,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY c.c_birth_year ORDER BY MAX(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        c.c_birth_year IS NOT NULL
        AND (cd.cd_gender = 'F' OR cd.cd_gender IS NULL)
        AND ws.ws_net_profit > 0
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_birth_year, cd.cd_gender
),
StorePerformance AS (
    SELECT 
        ss.ss_store_sk,
        SUM(ss.ss_net_profit) AS total_store_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_sales,
        AVG(ss.ss_sales_price) AS avg_sales_price
    FROM 
        store_sales ss
    JOIN 
        store s ON ss.ss_store_sk = s.s_store_sk
    WHERE 
        s.s_state = 'CA'
        AND ss.ss_sold_date_sk >= (
            SELECT MIN(d.d_date_sk) 
            FROM date_dim d 
            WHERE d.d_year = 2023
        )
    GROUP BY 
        ss.ss_store_sk
)
SELECT 
    cp.c_customer_sk,
    cp.c_first_name,
    cp.c_last_name,
    cp.max_net_profit,
    sp.total_store_profit,
    sp.total_sales
FROM 
    CustomerPerformance cp
JOIN 
    StorePerformance sp ON cp.max_net_profit = (
        SELECT MAX(total_store_profit) 
        FROM StorePerformance 
        WHERE total_sales > 5
    )
WHERE 
    cp.profit_rank = 1 
    OR cp.c_birth_year IN (
        SELECT DISTINCT c.c_birth_year
        FROM customer c
        WHERE c.c_birth_year IS NOT NULL
        AND EXISTS (
            SELECT 1 FROM web_sales ws
            WHERE ws.ws_ship_customer_sk = c.c_customer_sk
            HAVING SUM(ws.ws_net_profit) < 500
        )
    )
ORDER BY 
    cp.c_last_name ASC, cp.c_first_name DESC;
