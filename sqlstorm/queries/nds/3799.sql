
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        ws_item_sk,
        ws_quantity,
        ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY ws_net_paid DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_ship_date_sk IS NOT NULL
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_state
    FROM 
        customer_demographics cd
    LEFT JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
IncomeStats AS (
    SELECT 
        hd.hd_income_band_sk,
        COUNT(*) AS household_count,
        AVG(hd.hd_vehicle_count) AS avg_vehicle_count
    FROM 
        household_demographics hd
    GROUP BY 
        hd.hd_income_band_sk
),
SalesSummary AS (
    SELECT 
        rs.ws_bill_customer_sk,
        SUM(rs.ws_quantity) AS total_quantity,
        SUM(rs.ws_net_paid) AS total_sales,
        MAX(rs.ws_net_paid) AS max_individual_sale
    FROM 
        RankedSales rs
    WHERE 
        rs.rank <= 5
    GROUP BY 
        rs.ws_bill_customer_sk
)
SELECT 
    cs.cd_gender,
    cs.cd_marital_status,
    cs.cd_education_status,
    cs.ca_state,
    ss.total_quantity,
    ss.total_sales,
    isd.household_count,
    isd.avg_vehicle_count
FROM 
    SalesSummary ss
JOIN 
    CustomerDemographics cs ON ss.ws_bill_customer_sk = cs.cd_demo_sk
LEFT JOIN 
    IncomeStats isd ON cs.cd_demo_sk = isd.hd_income_band_sk
WHERE 
    (ss.total_sales > 1000 OR cs.cd_gender = 'F')
    AND ss.total_quantity > 10
ORDER BY 
    ss.total_sales DESC, cs.cd_gender ASC;
