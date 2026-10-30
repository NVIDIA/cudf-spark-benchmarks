
WITH HighValueCustomers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate > (
            SELECT AVG(cd_inner.cd_purchase_estimate) 
            FROM customer_demographics cd_inner
        )
),
SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_sold_date_sk
),
StoreSalesStats AS (
    SELECT 
        ss.ss_store_sk,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        AVG(ss.ss_net_profit) AS avg_net_profit
    FROM 
        store_sales ss
    GROUP BY 
        ss.ss_store_sk
),
OrderedHighValue AS (
    SELECT 
        c.*, 
        ROW_NUMBER() OVER (PARTITION BY c.cd_gender ORDER BY c.cd_purchase_estimate DESC) AS rank
    FROM 
        HighValueCustomers c
)

SELECT 
    hv.c_first_name,
    hv.c_last_name,
    hv.cd_gender,
    ss.total_sales,
    ss.avg_net_profit,
    sd.total_profit,
    sd.order_count
FROM 
    OrderedHighValue hv
LEFT JOIN 
    StoreSalesStats ss ON ss.ss_store_sk = hv.c_customer_sk
LEFT JOIN 
    SalesData sd ON sd.ws_sold_date_sk = (SELECT MAX(ws_sold_date_sk) FROM SalesData)
WHERE 
    hv.rank <= 10
AND 
    ss.total_sales IS NOT NULL
ORDER BY 
    hv.cd_gender, hv.cd_purchase_estimate DESC;

