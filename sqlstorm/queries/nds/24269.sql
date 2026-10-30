
WITH  CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_profit) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank_sales
    FROM 
        customer c 
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk 
    GROUP BY 
        c.c_customer_sk
),
IncomeDemographics AS (
    SELECT 
        h.hd_demo_sk,
        SUM(ss.ss_net_profit) AS total_store_sales,
        ABS(AVG(ss.ss_list_price - ss.ss_net_paid)) AS avg_price_difference,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count
    FROM 
        household_demographics h
    JOIN 
        store_sales ss ON h.hd_demo_sk = ss.ss_cdemo_sk
    WHERE 
        h.hd_income_band_sk IS NOT NULL
    GROUP BY 
        h.hd_demo_sk
),
AggregatedData AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_sales,
        cs.order_count,
        COALESCE(id.total_store_sales, 0) AS total_store_sales,
        COALESCE(id.avg_price_difference, 0) AS avg_price_difference,
        COALESCE(id.store_order_count, 0) AS store_order_count
    FROM 
        CustomerSales cs
    FULL OUTER JOIN 
        IncomeDemographics id ON cs.c_customer_sk = id.hd_demo_sk
)
SELECT 
    a.c_customer_sk,
    a.total_sales,
    a.order_count,
    a.total_store_sales,
    a.avg_price_difference,
    a.store_order_count,
    CASE 
        WHEN a.total_sales > 1000 THEN 'High Value Customer' 
        WHEN a.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value,
    CASE 
        WHEN a.total_store_sales = 0 THEN 'No Store Sales'
        WHEN a.store_order_count = 0 THEN 'No Store Orders'
        ELSE 'Active Store Customer'
    END AS store_activity_status
FROM 
    AggregatedData a
WHERE 
    (a.total_sales IS NOT NULL OR a.total_store_sales IS NOT NULL)
ORDER BY 
    CASE 
        WHEN a.total_sales IS NOT NULL THEN 
            CASE 
                WHEN a.total_sales > 1000 THEN 1 
                WHEN a.total_sales BETWEEN 500 AND 1000 THEN 2 
                ELSE 3 
            END
        ELSE 4
    END, 
    a.total_sales DESC 
LIMIT 100;
