
WITH RankedSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_ship_date_sk,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY ws.ws_sales_price DESC) AS rn
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sales_price > (
            SELECT 
                AVG(ws_inner.ws_sales_price) 
            FROM 
                web_sales ws_inner 
            WHERE 
                ws_inner.ws_bill_customer_sk = c.c_customer_sk
        )
),
SalesSummary AS (
    SELECT 
        r.c_customer_sk,
        r.c_first_name,
        r.c_last_name,
        SUM(r.ws_sales_price) AS total_sales,
        COUNT(r.ws_order_number) AS total_orders
    FROM 
        RankedSales r
    WHERE 
        r.rn <= 5
    GROUP BY 
        r.c_customer_sk, r.c_first_name, r.c_last_name
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer_demographics cd
    WHERE 
        cd.cd_demo_sk IN (SELECT DISTINCT c.c_current_cdemo_sk FROM customer c)
)
SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.total_sales,
    cs.total_orders,
    CASE 
        WHEN cd.cd_gender = 'M' THEN 'Male'
        WHEN cd.cd_gender = 'F' THEN 'Female'
        ELSE 'Unknown'
    END AS gender,
    COALESCE(cd.cd_marital_status, 'Not Specified') AS marital_status,
    cd.cd_purchase_estimate,
    (SELECT ib.ib_income_band_sk 
     FROM household_demographics hd 
     JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk 
     WHERE hd.hd_demo_sk = cs.c_customer_sk LIMIT 1) AS income_band_sk
FROM 
    SalesSummary cs
LEFT JOIN 
    CustomerDemographics cd ON cs.c_customer_sk = cd.cd_demo_sk
WHERE 
    (cs.total_sales > 1000 OR cs.total_orders > 10)
    AND NOT EXISTS (
        SELECT 1
        FROM store_sales ss
        WHERE ss.ss_customer_sk = cs.c_customer_sk
          AND ss.ss_sales_price < 0
    )
ORDER BY 
    cs.total_sales DESC, cs.total_orders ASC
LIMIT 100;
