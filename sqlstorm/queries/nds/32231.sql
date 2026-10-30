
WITH  SalesHierarchy AS (
    SELECT 
        s.s_store_name,
        s.s_store_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY s.s_store_name ORDER BY SUM(ss_ext_sales_price) DESC) AS rank
    FROM 
        store s
    LEFT JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s.s_store_name, s.s_store_sk
), 
CustomerSegmentation AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ib.ib_income_band_sk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON hd.hd_demo_sk = cd.cd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE 
        cd.cd_purchase_estimate > 500
), 
RankedCustomers AS (
    SELECT 
        c.*,
        ROW_NUMBER() OVER (ORDER BY c.cd_purchase_estimate DESC) AS customer_rank
    FROM 
        CustomerSegmentation c
)

SELECT 
    r.s_store_name,
    COUNT(DISTINCT rc.c_customer_sk) AS number_of_customers,
    AVG(rc.cd_purchase_estimate) AS avg_purchase_estimate,
    COALESCE(SUM(ws_sales_price), 0) AS total_web_sales
FROM 
    SalesHierarchy r
LEFT JOIN 
    web_sales ws ON r.s_store_sk = ws.ws_warehouse_sk
LEFT JOIN 
    RankedCustomers rc ON rc.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    r.rank <= 5
GROUP BY 
    r.s_store_name
HAVING 
    AVG(rc.cd_purchase_estimate) > 1000
ORDER BY 
    total_web_sales DESC
LIMIT 10;
