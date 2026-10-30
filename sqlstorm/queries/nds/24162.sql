
WITH IncomeBands AS (
    SELECT 
        ib_income_band_sk AS income_band_id,
        COALESCE(ib_lower_bound, 0) AS lower_bound,
        COALESCE(ib_upper_bound, 999999) AS upper_bound
    FROM income_band
), CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank,
        COALESCE(cd.cd_dep_count, 0) AS dep_count_adjusted
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sales,
        AVG(ws.ws_sales_price) AS average_sales_price,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
), RankedSales AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_sales,
        sd.average_sales_price,
        sd.total_net_profit,
        RANK() OVER (ORDER BY sd.total_sales DESC) AS sales_rank
    FROM SalesData sd
)
SELECT 
    ci.c_customer_id,
    ci.cd_gender,
    ib.income_band_id,
    rs.total_sales,
    rs.average_sales_price,
    rs.total_net_profit,
    (rs.total_net_profit / NULLIF(rs.total_sales, 0)) AS profit_per_sale,
    COALESCE(rs.total_sales, 0) AS sales_with_coalesce,
    DENSE_RANK() OVER (PARTITION BY ci.cd_gender ORDER BY rs.total_net_profit DESC) AS profit_rank
FROM CustomerInfo ci
LEFT JOIN IncomeBands ib ON ci.cd_purchase_estimate BETWEEN ib.lower_bound AND ib.upper_bound
LEFT JOIN RankedSales rs ON ci.c_customer_sk = rs.ws_item_sk
WHERE (ci.cd_marital_status = 'M' OR ci.cd_gender = 'F')
  AND rs.sales_rank <= 10
  AND (rs.average_sales_price IS NOT NULL OR ci.dep_count_adjusted > 0)
ORDER BY ci.c_customer_id, rs.total_sales DESC
LIMIT 100;
