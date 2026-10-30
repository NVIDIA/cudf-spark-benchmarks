
WITH Income_Categories AS (
    SELECT 
        ib_income_band_sk,
        ib_lower_bound,
        ib_upper_bound,
        CASE 
            WHEN ib_income_band_sk IS NULL THEN 'Unknown'
            WHEN ib_lower_bound < 30000 THEN 'Low Income'
            WHEN ib_lower_bound < 70000 THEN 'Middle Income'
            ELSE 'High Income' 
        END AS income_category
    FROM income_band
),
Sales_Stats AS (
    SELECT
        cs.cs_item_sk,
        COUNT(cs.cs_order_number) AS total_orders,
        SUM(cs.cs_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_net_profit
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    GROUP BY cs.cs_item_sk
),
Return_Stats AS (
    SELECT
        cr.cr_item_sk,
        COUNT(cr.cr_order_number) AS total_returns,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM catalog_returns cr
    GROUP BY cr.cr_item_sk
),
Final_Stats AS (
    SELECT 
        ss.cs_item_sk,
        ss.total_orders,
        ss.total_sales,
        ss.total_net_profit,
        COALESCE(rs.total_returns, 0) AS total_returns,
        COALESCE(rs.total_return_amount, 0) AS total_return_amount,
        ic.income_category
    FROM Sales_Stats ss
    LEFT JOIN Return_Stats rs ON ss.cs_item_sk = rs.cr_item_sk
    LEFT JOIN customer c ON ss.cs_item_sk = c.c_customer_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN Income_Categories ic ON hd.hd_income_band_sk = ic.ib_income_band_sk
)
SELECT 
    item.i_item_id,
    item.i_item_desc,
    fs.total_orders,
    fs.total_sales,
    fs.total_net_profit,
    fs.total_returns,
    fs.total_return_amount,
    fs.income_category
FROM Final_Stats fs
JOIN item ON fs.cs_item_sk = item.i_item_sk
WHERE fs.total_sales > 1000
ORDER BY fs.total_net_profit DESC, fs.total_orders DESC
LIMIT 50;
