
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1 AND 365
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
StoreSales AS (
    SELECT 
        ss.ss_store_sk,
        SUM(ss.ss_ext_sales_price) AS total_store_sales
    FROM 
        store_sales ss
    WHERE 
        ss.ss_sold_date_sk BETWEEN 1 AND 365
    GROUP BY 
        ss.ss_store_sk
),
AverageIncome AS (
    SELECT 
        hd.hd_income_band_sk,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        household_demographics hd
    JOIN 
        customer_demographics cd ON hd.hd_demo_sk = cd.cd_demo_sk
    GROUP BY 
        hd.hd_income_band_sk
),
CombinedSales AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_web_sales,
        ss.total_store_sales,
        COALESCE(ss.total_store_sales, 0) AS store_sales,
        CASE 
            WHEN cs.total_web_sales > 0 THEN 'Web'
            ELSE 'Store'
        END AS preferred_channel
    FROM 
        CustomerSales cs
    LEFT JOIN 
        StoreSales ss ON cs.c_customer_sk = ss.ss_store_sk
)
SELECT 
    csk.c_customer_sk,
    CONCAT(csk.c_first_name, ' ', csk.c_last_name) AS customer_name,
    cs.total_web_sales,
    cs.store_sales,
    cs.preferred_channel,
    ib.ib_lower_bound,
    avg_income.avg_purchase_estimate,
    CASE 
        WHEN cs.total_web_sales IS NULL THEN 'No web sales'
        ELSE 'Web sales recorded'
    END AS web_sales_status
FROM 
    CombinedSales cs
JOIN 
    customer csk ON cs.c_customer_sk = csk.c_customer_sk
LEFT JOIN 
    income_band ib ON csk.c_current_cdemo_sk = ib.ib_income_band_sk
LEFT JOIN 
    AverageIncome avg_income ON csk.c_current_cdemo_sk = avg_income.hd_income_band_sk
ORDER BY 
    cs.total_web_sales DESC, 
    cs.store_sales ASC 
LIMIT 100;
