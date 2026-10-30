
WITH  SalesStats AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sales_quantity,
        SUM(ws_net_paid) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS sales_rank
    FROM 
        web_sales 
    GROUP BY 
        ws_item_sk
), 
TopItems AS (
    SELECT
        i.i_item_id,
        i.i_item_desc,
        ss.total_sales_quantity,
        ss.total_net_paid
    FROM 
        SalesStats ss
    JOIN 
        item i ON ss.ws_item_sk = i.i_item_sk
    WHERE 
        ss.sales_rank <= 10
), 
StoreSales AS (
    SELECT 
        s.s_store_id, 
        SUM(ss.ss_sales_price) AS total_store_sales
    FROM 
        store_sales ss
    JOIN 
        store s ON ss.ss_store_sk = s.s_store_sk
    GROUP BY 
        s.s_store_id
),
CustomerIncome AS (
    SELECT 
        c.c_customer_id,
        hd.hd_income_band_sk,
        COUNT(c.c_customer_sk) AS customer_count
    FROM 
        customer c
    JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    GROUP BY 
        c.c_customer_id, hd.hd_income_band_sk
)
SELECT 
    ti.i_item_desc,
    ti.total_sales_quantity,
    ti.total_net_paid,
    ss.total_store_sales,
    ci.hd_income_band_sk,
    ci.customer_count
FROM 
    TopItems ti
LEFT JOIN 
    StoreSales ss ON ti.i_item_id = ss.s_store_id
LEFT JOIN 
    CustomerIncome ci ON ci.hd_income_band_sk = CASE 
                                                  WHEN ti.total_net_paid > 1000 THEN 1
                                                  WHEN ti.total_net_paid BETWEEN 500 AND 1000 THEN 2
                                                  ELSE 3 
                                                END
WHERE 
    ti.total_sales_quantity IS NOT NULL
ORDER BY 
    ti.total_sales_quantity DESC
LIMIT 50;
