
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(*) AS total_transactions,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
), 
CustomerStatistics AS (
    SELECT 
        c_customer_sk,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(c_customer_sk) AS num_purchases
    FROM 
        customer 
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    WHERE 
        cd_gender = 'F' AND cd_marital_status = 'M'
    GROUP BY 
        c_customer_sk
),
ItemReturns AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returns,
        SUM(wr_return_amt_inc_tax) AS total_return_value
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
)
SELECT 
    i.i_item_desc,
    rs.total_sales,
    rs.total_transactions,
    COALESCE(ir.total_returns, 0) AS total_returns,
    COALESCE(ir.total_return_value, 0) AS total_return_value,
    cs.avg_purchase_estimate,
    cs.num_purchases
FROM 
    item i
LEFT JOIN 
    RankedSales rs ON i.i_item_sk = rs.ws_item_sk
LEFT JOIN 
    ItemReturns ir ON i.i_item_sk = ir.wr_item_sk
LEFT JOIN 
    CustomerStatistics cs ON rs.total_sales > 1000
WHERE 
    i.i_current_price IS NOT NULL
ORDER BY 
    rs.total_sales DESC
LIMIT 100;
