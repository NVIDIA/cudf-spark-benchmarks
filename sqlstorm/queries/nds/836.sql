
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rank
    FROM 
        web_sales 
    WHERE 
        ws_ship_date_sk BETWEEN 10000 AND 10100
    GROUP BY 
        ws_item_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        COALESCE(hd.hd_income_band_sk, -1) AS income_band,
        CASE 
            WHEN cd.cd_marital_status = 'M' THEN 'Married'
            WHEN cd.cd_marital_status = 'S' THEN 'Single'
            ELSE 'Other' 
        END AS marital_status
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
SalesWithCustomer AS (
    SELECT 
        s.ss_item_sk,
        SUM(s.ss_net_paid) AS total_net_paid,
        ci.cd_gender,
        ci.income_band,
        ci.marital_status,
        ROW_NUMBER() OVER (PARTITION BY s.ss_item_sk ORDER BY SUM(s.ss_net_paid) DESC) AS rank
    FROM 
        store_sales s
    JOIN 
        CustomerInfo ci ON s.ss_customer_sk = ci.c_customer_sk
    GROUP BY 
        s.ss_item_sk, ci.cd_gender, ci.income_band, ci.marital_status
),
FinalResults AS (
    SELECT 
        ws.ws_item_sk AS item_sk,
        ws.total_sales AS web_total_sales,
        COALESCE(sc.total_net_paid, 0) AS store_total_net_paid,
        (ws.total_sales - COALESCE(sc.total_net_paid, 0)) AS sales_difference,
        ci.marital_status
    FROM 
        RankedSales ws
    LEFT JOIN 
        SalesWithCustomer sc ON ws.ws_item_sk = sc.ss_item_sk
    LEFT JOIN 
        CustomerInfo ci ON ci.income_band = CASE 
            WHEN ws.total_sales < 1000 THEN 1
            WHEN ws.total_sales BETWEEN 1000 AND 5000 THEN 2
            WHEN ws.total_sales > 5000 THEN 3
            ELSE NULL
        END
    WHERE 
        ws.rank = 1
)
SELECT 
    item_sk, 
    web_total_sales, 
    store_total_net_paid, 
    sales_difference, 
    COUNT(*) AS customer_count
FROM 
    FinalResults
GROUP BY 
    item_sk, web_total_sales, store_total_net_paid, sales_difference
HAVING 
    COUNT(*) > 1
ORDER BY 
    web_total_sales DESC, store_total_net_paid ASC;
