WITH CustomerStats AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT c_customer_sk) AS total_customers,
        SUM(CASE WHEN cd_purchase_estimate IS NOT NULL THEN cd_purchase_estimate ELSE 0 END) AS total_spending,
        AVG(COALESCE(cd_dep_count, 0)) AS avg_dependents
    FROM 
        customer_demographics
    JOIN 
        customer ON customer.c_current_cdemo_sk = customer_demographics.cd_demo_sk
    GROUP BY 
        cd_gender, cd_marital_status
),
ReturnStats AS (
    SELECT 
        sr_reason_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount,
        AVG(sr_return_quantity) AS avg_return_per_item
    FROM 
        store_returns
    GROUP BY 
        sr_reason_sk
),
SalesStats AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_sales_price) AS total_sales_value,
        AVG(ws_sales_price) AS avg_sales_price
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
FilteredSales AS (
    SELECT 
        s.ws_item_sk,
        s.total_quantity_sold,
        s.total_sales_value,
        s.avg_sales_price,
        CASE 
            WHEN r.total_returns IS NULL THEN 0
            ELSE r.total_returns 
        END AS total_returns
    FROM 
        SalesStats s
    LEFT JOIN 
        ReturnStats r ON s.ws_item_sk = r.sr_reason_sk
    WHERE 
        s.total_sales_value > (SELECT AVG(total_sales_value) FROM SalesStats) 
        AND r.total_returns IS NULL OR r.total_returns < 5 
),
FinalAggregation AS (
    SELECT 
        cs.cd_gender,
        cs.cd_marital_status,
        SUM(fs.total_quantity_sold) AS total_sold_items,
        SUM(fs.total_sales_value) AS total_sales,
        SUM(CASE WHEN fs.total_returns = 0 THEN 1 ELSE 0 END) AS items_never_returned,
        AVG(fs.avg_sales_price) AS avg_price_per_item
    FROM 
        CustomerStats cs
    JOIN 
        FilteredSales fs ON fs.ws_item_sk IN (SELECT i_item_sk FROM item WHERE i_brand_id IN (SELECT DISTINCT i_brand_id FROM item WHERE i_current_price > 20))
    GROUP BY 
        cs.cd_gender, cs.cd_marital_status
)

SELECT 
    fa.cd_gender,
    fa.cd_marital_status,
    fa.total_sold_items,
    fa.total_sales,
    fa.items_never_returned,
    fa.avg_price_per_item,
    ROW_NUMBER() OVER (PARTITION BY fa.cd_gender ORDER BY fa.total_sales DESC) AS sales_rank
FROM 
    FinalAggregation fa
WHERE 
    fa.total_sold_items > 1000 OR fa.total_sales IS NULL
ORDER BY 
    fa.cd_gender, sales_rank;