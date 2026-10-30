
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        ws_item_sk,
        ws_order_number,
        ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY ws_ext_sales_price DESC) AS rnk
    FROM 
        web_sales
),
ItemReturns AS (
    SELECT 
        wr_returning_customer_sk,
        wr_item_sk,
        COUNT(*) AS return_count,
        SUM(wr_return_amt) AS total_return_amt
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk, wr_item_sk
),
HighReturnItems AS (
    SELECT 
        ir.wr_item_sk,
        ir.return_count,
        ir.total_return_amt
    FROM 
        ItemReturns ir
    JOIN RankedSales rs ON ir.wr_item_sk = rs.ws_item_sk
    WHERE 
        ir.return_count > 10 AND rs.rnk <= 5
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(ib.ib_income_band_sk, 0) AS income_band,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON hd.hd_demo_sk = cd.cd_demo_sk
    LEFT JOIN income_band ib ON ib.ib_income_band_sk = hd.hd_income_band_sk
    LEFT JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, ib.ib_income_band_sk
)
SELECT 
    cd.income_band,
    cd.cd_gender,
    AVG(cd.total_orders) AS avg_orders,
    SUM(hr.return_count) AS total_returns,
    SUM(hr.total_return_amt) AS total_return_amount
FROM 
    CustomerDemographics cd
LEFT JOIN HighReturnItems hr ON hr.wr_item_sk IN (SELECT DISTINCT ws_item_sk FROM web_sales WHERE ws_bill_customer_sk = cd.cd_demo_sk)
WHERE 
    cd.total_orders > 5
GROUP BY 
    cd.income_band, cd.cd_gender
HAVING 
    SUM(hr.return_count) IS NOT NULL
ORDER BY 
    avg_orders DESC;
