
WITH  SalesAnalysis AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_ship_tax) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid_inc_ship_tax) DESC) AS sales_rank
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk BETWEEN 1 AND 30
    GROUP BY 
        ws_item_sk
),
TopSales AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        sales_analysis.total_quantity,
        sales_analysis.total_sales,
        DENSE_RANK() OVER (ORDER BY sales_analysis.total_sales DESC) AS rank
    FROM 
        SalesAnalysis sales_analysis
    JOIN 
        item ON sales_analysis.ws_item_sk = item.i_item_sk
    WHERE 
        sales_analysis.sales_rank <= 5
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(NULLIF(cd.cd_credit_rating, 'Normal'), 'Unknown') AS credit_rating,
        hd.hd_income_band_sk
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
),
ReturnMetrics AS (
    SELECT 
        item.i_item_id,
        COUNT(DISTINCT wr.wr_order_number) AS web_returns,
        COUNT(DISTINCT cr.cr_order_number) AS catalog_returns
    FROM 
        web_returns wr
    FULL OUTER JOIN 
        catalog_returns cr ON wr.wr_item_sk = cr.cr_item_sk
    JOIN 
        item ON wr.wr_item_sk = item.i_item_sk OR cr.cr_item_sk = item.i_item_sk
    GROUP BY 
        item.i_item_id
)
SELECT 
    ts.i_item_id,
    ts.i_item_desc,
    ts.total_quantity,
    ts.total_sales,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.credit_rating,
    rb.web_returns + rb.catalog_returns AS total_returns,
    CASE 
        WHEN rb.web_returns > rb.catalog_returns THEN 'Web Dominant'
        WHEN rb.catalog_returns > rb.web_returns THEN 'Catalog Dominant'
        ELSE 'Equal Returns'
    END AS return_dominance
FROM 
    TopSales ts
JOIN 
    CustomerDemographics cd ON cd.hd_income_band_sk IN (
        SELECT ib.ib_income_band_sk 
        FROM income_band ib 
        WHERE ib.ib_lower_bound <= (SELECT MAX(ts2.total_sales) FROM TopSales ts2) 
        AND ib.ib_upper_bound >= (SELECT MIN(ts2.total_sales) FROM TopSales ts2)
    )
JOIN 
    ReturnMetrics rb ON ts.i_item_id = rb.i_item_id 
ORDER BY 
    ts.total_sales DESC, ts.total_quantity DESC;
