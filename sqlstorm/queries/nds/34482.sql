
WITH  SalesHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        ss.ss_quantity,
        ss.ss_net_paid,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY ss.ss_sold_date_sk DESC) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        ss.ss_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
),
ProductSales AS (
    SELECT 
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    WHERE 
        i.i_current_price IS NOT NULL
    GROUP BY 
        i.i_item_id
)
SELECT 
    sh.c_first_name,
    sh.c_last_name,
    sh.cd_gender,
    COALESCE(ps.total_quantity, 0) AS total_quantity_sold,
    COALESCE(ps.total_profit, 0) AS total_profit_generated,
    sh.ss_net_paid AS net_paid_amount,
    DENSE_RANK() OVER (ORDER BY COALESCE(ps.total_profit, 0) DESC) AS profit_rank
FROM 
    SalesHierarchy sh
LEFT JOIN 
    ProductSales ps ON sh.c_customer_sk = ps.total_quantity 
WHERE 
    sh.rn = 1
    AND sh.ss_net_paid > 100
    OR sh.cd_gender = 'F'
ORDER BY 
    profit_rank
LIMIT 50;
