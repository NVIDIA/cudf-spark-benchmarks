
WITH SalesData AS (
    SELECT 
        s.s_store_id,
        w.w_warehouse_id,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_net_paid) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS transaction_count
    FROM 
        store s
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    JOIN 
        warehouse w ON s.s_store_sk = w.w_warehouse_sk
    WHERE 
        ss.ss_sold_date_sk BETWEEN 1000 AND 2000
    GROUP BY 
        s.s_store_id, w.w_warehouse_id
),
CustomerData AS (
    SELECT
        cd.cd_gender,
        SUM(CASE WHEN ws.ws_net_profit > 0 THEN 1 ELSE 0 END) AS positive_profit_count,
        AVG(COALESCE(cd.cd_purchase_estimate, 0)) AS avg_purchase_estimate
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 2000
    GROUP BY 
        cd.cd_gender
),
TopBrands AS (
    SELECT 
        i.i_item_id,
        i.i_brand,
        SUM(ws.ws_sales_price) AS brand_sales
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_id, i.i_brand
    HAVING 
        SUM(ws.ws_sales_price) > 10000
)
SELECT 
    sd.s_store_id,
    sd.w_warehouse_id,
    cd.cd_gender,
    cd.positive_profit_count,
    cd.avg_purchase_estimate,
    tb.i_item_id,
    tb.i_brand,
    tb.brand_sales
FROM 
    SalesData sd
LEFT JOIN 
    CustomerData cd ON 1=1
CROSS JOIN 
    TopBrands tb
WHERE 
    (sd.total_sales IS NOT NULL AND sd.total_sales > 5000)
    OR (cd.avg_purchase_estimate IS NOT NULL AND cd.avg_purchase_estimate < 100)
ORDER BY 
    sd.total_quantity DESC, 
    cd.avg_purchase_estimate ASC;
