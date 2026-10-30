
WITH RankedSales AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_order_number, ws_item_sk
), 
TopSellingItems AS (
    SELECT 
        ws_item_sk,
        AVG(total_sales) AS avg_sales
    FROM 
        RankedSales
    WHERE 
        sales_rank = 1
    GROUP BY 
        ws_item_sk
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        COALESCE(ib.ib_lower_bound, 0) AS lower_bound,
        COALESCE(ib.ib_upper_bound, 1000000) AS upper_bound
    FROM 
        item i
    LEFT JOIN 
        income_band ib ON i.i_item_sk = ib.ib_income_band_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate > (SELECT AVG(cd_purchase_estimate) FROM customer_demographics)
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    itemDetails.i_item_id,
    itemDetails.i_product_name,
    sales.avg_sales,
    demographic.cd_gender,
    demographic.cd_marital_status,
    demographic.customer_count,
    CASE 
        WHEN itemDetails.lower_bound IS NULL OR itemDetails.upper_bound IS NULL 
        THEN 'Unbounded'
        ELSE CONCAT('Income Range: ', itemDetails.lower_bound, ' - ', itemDetails.upper_bound)
    END AS income_range
FROM 
    TopSellingItems sales
JOIN 
    ItemDetails itemDetails ON sales.ws_item_sk = itemDetails.i_item_sk
LEFT JOIN 
    CustomerDemographics demographic ON demographic.customer_count > 0
WHERE 
    itemDetails.i_item_sk IS NOT NULL
ORDER BY 
    sales.avg_sales DESC, demographic.cd_gender, demographic.customer_count DESC
LIMIT 10;
