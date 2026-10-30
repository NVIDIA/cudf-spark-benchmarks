
WITH SalesSummary AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_coupon_amt) AS total_coupons,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY ws.ws_sold_date_sk, ws.ws_item_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(hd.hd_income_band_sk, 999) AS income_band,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, hd.hd_income_band_sk
),
MaxSales AS (
    SELECT 
        ss.ws_item_sk,
        MAX(ss.total_sales) AS max_sales
    FROM SalesSummary ss
    GROUP BY ss.ws_item_sk
)
SELECT 
    cs.cd_gender,
    cs.cd_marital_status,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    SUM(cs.customer_count) AS total_customers,
    COUNT(DISTINCT CASE WHEN ss.total_sales = ms.max_sales THEN ss.ws_item_sk END) AS best_selling_item_count
FROM CustomerDemographics cs
JOIN MaxSales ms ON cs.income_band = ms.ws_item_sk
JOIN income_band ib ON cs.income_band = ib.ib_income_band_sk
LEFT JOIN SalesSummary ss ON ms.ws_item_sk = ss.ws_item_sk
GROUP BY cs.cd_gender, cs.cd_marital_status, ib.ib_lower_bound, ib.ib_upper_bound
HAVING COUNT(DISTINCT cs.cd_demo_sk) > 10
ORDER BY total_customers DESC, best_selling_item_count DESC;
