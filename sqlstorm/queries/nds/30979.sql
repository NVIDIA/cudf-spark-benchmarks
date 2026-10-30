
WITH  SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2452022 AND 2452106 
    GROUP BY 
        ws_item_sk
),
CustomerRanked AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(COALESCE(ss.ss_net_profit, 0)) AS total_net_profit,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(COALESCE(ss.ss_net_profit, 0)) DESC) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
TopItems AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_sales,
        sd.total_orders
    FROM 
        SalesData sd
    WHERE 
        sd.sales_rank <= 10
)
SELECT 
    ti.ws_item_sk,
    ti.total_sales,
    ti.total_orders,
    cr.c_customer_sk,
    cr.cd_gender,
    cr.cd_marital_status,
    cr.total_net_profit,
    CASE 
        WHEN cr.gender_rank = 1 THEN 'Top spender in gender'
        ELSE 'Lower spender in gender' 
    END AS spender_category
FROM 
    TopItems ti
JOIN 
    CustomerRanked cr ON ti.ws_item_sk = cr.c_customer_sk -- Corrected join condition
WHERE 
    cr.total_net_profit IS NOT NULL
ORDER BY 
    ti.total_sales DESC, cr.total_net_profit ASC
LIMIT 100;
