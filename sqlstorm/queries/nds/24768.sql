
WITH RecursiveAddress AS (
    SELECT 
        ca_address_sk,
        ca_city,
        ca_state,
        ca_zip,
        ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY ca_city) AS row_num
    FROM 
        customer_address
    WHERE 
        ca_zip IS NOT NULL
        AND ca_city <> ''
),
CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate > (
            SELECT AVG(cd_purchase_estimate) 
            FROM customer_demographics 
            WHERE cd_gender = 'M'
        )
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(CASE WHEN ws.ws_item_sk IS NULL THEN 1 END) AS null_item_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
CopySalesData AS (
    SELECT 
        cs.cs_item_sk,
        SUM(cs.cs_net_paid) AS total_net_paid
    FROM 
        catalog_sales cs
    GROUP BY 
        cs.cs_item_sk
),
FinalReport AS (
    SELECT 
        ca.row_num,
        ca.ca_city,
        ca.ca_state,
        cd.c_customer_id,
        cd.c_first_name,
        cd.c_last_name,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(sd.order_count, 0) AS order_count,
        COALESCE(sd.total_profit, 0) AS total_profit,
        CASE 
            WHEN sd.null_item_count > 0 THEN 'Items have NULL values'
            ELSE 'All items present'
        END AS item_status,
        ib.ib_income_band_sk
    FROM 
        RecursiveAddress ca
    LEFT JOIN 
        CustomerDetails cd ON cd.rank <= 5
    LEFT JOIN 
        SalesData sd ON sd.ws_item_sk = ca.ca_address_sk
    LEFT JOIN 
        income_band ib ON ib.ib_lower_bound <= cd.cd_purchase_estimate AND ib.ib_upper_bound >= cd.cd_purchase_estimate
),
AggregatedReport AS (
    SELECT 
        f.ca_city,
        f.ca_state,
        COUNT(DISTINCT f.c_customer_id) AS customer_count,
        SUM(f.total_sales) AS sum_sales,
        AVG(f.total_profit) AS avg_profit,
        STRING_AGG(f.item_status, ', ') AS status_summary
    FROM 
        FinalReport f
    GROUP BY 
        f.ca_city, f.ca_state
)
SELECT 
    a.ca_city,
    a.ca_state,
    a.customer_count,
    a.sum_sales,
    (CASE 
        WHEN a.avg_profit IS NULL THEN 'No Profit'
        ELSE CAST(a.avg_profit AS STRING)
    END) AS average_profit,
    CASE 
        WHEN EXISTS (
            SELECT 1
            FROM customer_demographics cd 
            WHERE cd.cd_marital_status = 'M' 
            AND cd.cd_purchase_estimate > 1000
        ) THEN 'High Purchase'
        ELSE 'Low Purchase'
    END AS purchase_category
FROM 
    AggregatedReport a
WHERE 
    a.customer_count > 0
ORDER BY 
    a.sum_sales DESC;
