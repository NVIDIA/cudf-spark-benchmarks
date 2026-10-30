
WITH SalesData AS (
    SELECT 
        ws_bill_customer_sk AS customer_id,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_ext_discount_amt) AS total_discounts,
        AVG(ws_ext_tax) AS avg_tax,
        SUM(ws_ext_ship_cost) AS total_shipping_cost
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) - 30 FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        ws_bill_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_credit_rating
    FROM 
        customer_demographics 
    WHERE 
        cd_demo_sk IN (SELECT DISTINCT c_current_cdemo_sk FROM customer)
),
SalesWithDemographics AS (
    SELECT 
        sd.customer_id,
        sd.total_sales,
        sd.total_orders,
        sd.total_discounts,
        sd.avg_tax,
        sd.total_shipping_cost,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_credit_rating
    FROM 
        SalesData sd
    LEFT JOIN 
        CustomerDemographics cd ON sd.customer_id = cd.cd_demo_sk
)
SELECT 
    COUNT(*) AS customer_count,
    AVG(total_sales) AS avg_sales,
    SUM(total_orders) AS total_orders,
    COUNT(DISTINCT cd_gender) AS gender_diversity,
    COUNT(DISTINCT cd_marital_status) AS marital_status_diversity,
    COUNT(DISTINCT cd_education_status) AS education_status_diversity,
    SUM(total_discounts) AS total_discounts_amount,
    AVG(avg_tax) AS avg_tax_amount,
    SUM(total_shipping_cost) AS total_shipping_cost
FROM 
    SalesWithDemographics
WHERE 
    total_sales > 100
GROUP BY 
    cd_gender, cd_marital_status, cd_education_status, cd_credit_rating
HAVING 
    COUNT(*) > 10;
