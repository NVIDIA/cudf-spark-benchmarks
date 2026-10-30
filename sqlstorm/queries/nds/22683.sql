
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS Total_Sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS Sales_Rank
    FROM web_sales
    GROUP BY ws_item_sk
),
CustomerGenderStats AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS Customer_Count,
        SUM(cd_purchase_estimate) AS Total_Purchases
    FROM customer
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY cd_gender
),
ReturnStats AS (
    SELECT 
        sr_item_sk,
        COUNT(*) AS Return_Count,
        SUM(sr_return_amt) AS Total_Return_Amount
    FROM store_returns
    GROUP BY sr_item_sk
),
ReturnRatio AS (
    SELECT 
        sr_item_sk,
        COALESCE(Return_Count, 0) AS Return_Count,
        COALESCE(Total_Return_Amount, 0) AS Total_Return_Amount,
        CASE 
            WHEN Total_Sales = 0 THEN NULL
            ELSE ROUND(RETURN_Count * 1.0 / Total_Sales, 4)
        END AS Return_Ratio
    FROM RankedSales
    LEFT JOIN ReturnStats ON ws_item_sk = sr_item_sk
),
FinalResults AS (
    SELECT 
        cg.cd_gender,
        SUM(rr.Return_Ratio) AS Avg_Return_Ratio,
        MAX(rr.Return_Ratio) AS Max_Return_Ratio,
        MIN(rr.Return_Ratio) AS Min_Return_Ratio
    FROM CustomerGenderStats AS cg
    LEFT JOIN ReturnRatio AS rr ON rr.sr_item_sk IN (
        SELECT ws_item_sk FROM web_sales WHERE ws_quantity > 0
    )
    GROUP BY cg.cd_gender
)

SELECT 
    fg.cd_gender,
    fg.Avg_Return_Ratio,
    fg.Max_Return_Ratio,
    fg.Min_Return_Ratio,
    COALESCE(ib.ib_lower_bound, -1) AS Income_Lower_Bound,
    COALESCE(ib.ib_upper_bound, 10000) AS Income_Upper_Bound
FROM FinalResults fg
LEFT JOIN household_demographics hd ON hd.hd_dep_count > 0
LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
ORDER BY fg.cd_gender;
