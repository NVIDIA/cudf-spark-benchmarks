
WITH RankedSales AS (
    SELECT 
        ws.ws_sold_date_sk,
        EXTRACT(YEAR FROM d.d_date) AS sales_year,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year >= 2020
),
TopSales AS (
    SELECT 
        sales_year,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price * ws_quantity) AS total_sales
    FROM 
        RankedSales
    WHERE 
        rn <= 5
    GROUP BY 
        sales_year, ws_item_sk
),
CustomerSummary AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_quantity) AS total_purchased,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_sales_price) AS avg_price_per_item
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
IncomeBandSummary AS (
    SELECT 
        ib.ib_income_band_sk,
        COUNT(hd.hd_demo_sk) AS household_count,
        MAX(COALESCE(cd.cd_purchase_estimate, 0)) AS max_purchase_estimate
    FROM 
        household_demographics hd
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN 
        customer_demographics cd ON hd.hd_demo_sk = cd.cd_demo_sk
    GROUP BY 
        ib.ib_income_band_sk
)
SELECT 
    cs.c_customer_sk,
    cs.cd_gender,
    cs.cd_marital_status,
    tp.sales_year,
    tp.total_quantity,
    tp.total_sales,
    ibs.household_count,
    ibs.max_purchase_estimate
FROM 
    CustomerSummary cs
LEFT JOIN 
    TopSales tp ON cs.total_purchased = tp.total_quantity
LEFT JOIN 
    IncomeBandSummary ibs ON cs.total_purchased BETWEEN ibs.household_count AND ibs.max_purchase_estimate
WHERE 
    (cs.cd_gender = 'F' OR cs.cd_marital_status IS NULL)
    AND (tp.total_sales IS NOT NULL AND tp.total_sales > 1000)
ORDER BY 
    cs.c_customer_sk,
    tp.sales_year DESC
LIMIT 100 OFFSET 0;
