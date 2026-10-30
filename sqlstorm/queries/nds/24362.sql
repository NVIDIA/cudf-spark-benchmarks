
WITH RankedSales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM
        web_sales ws
    GROUP BY
        ws.ws_order_number, ws.ws_item_sk
),
TopSales AS (
    SELECT 
        rs.ws_order_number,
        rs.ws_item_sk,
        rs.total_quantity,
        rs.total_sales
    FROM 
        RankedSales rs
    WHERE 
        rs.sales_rank <= 5
),
CustomerInfo AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        COALESCE(cd.cd_dep_count, 0) AS dep_count,
        COALESCE(cd.cd_dep_college_count, 0) AS dep_college_count
    FROM
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
SalesAndCustomer AS (
    SELECT
        cs.c_customer_sk,
        ts.total_sales,
        CASE
            WHEN ts.total_sales > 1000 THEN 'High'
            WHEN ts.total_sales BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS sales_category
    FROM
        TopSales ts
    JOIN CustomerInfo cs ON cs.c_customer_sk = ts.ws_item_sk
),
FinalReport AS (
    SELECT
        sac.sales_category,
        COUNT(DISTINCT sac.c_customer_sk) AS customer_count,
        AVG(sac.total_sales) AS avg_sales,
        SUM(CASE WHEN sac.sales_category = 'High' THEN sac.total_sales ELSE 0 END) AS high_sales_total,
        SUM(CASE WHEN sac.sales_category = 'Medium' THEN sac.total_sales ELSE 0 END) AS medium_sales_total,
        SUM(CASE WHEN sac.sales_category = 'Low' THEN sac.total_sales ELSE 0 END) AS low_sales_total
    FROM
        SalesAndCustomer sac
    GROUP BY
        sac.sales_category
)
SELECT 
    fr.sales_category,
    fr.customer_count,
    fr.avg_sales,
    fr.high_sales_total,
    fr.medium_sales_total,
    fr.low_sales_total
FROM 
    FinalReport fr
WHERE 
    fr.customer_count IS NOT NULL
    AND (fr.avg_sales > (SELECT AVG(avg_sales) FROM FinalReport) OR fr.sales_category = 'High')
ORDER BY
    fr.sales_category;
