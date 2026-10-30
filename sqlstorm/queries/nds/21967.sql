
WITH  AddressStats AS (
    SELECT
        ca_address_sk,
        ca_city,
        ca_state,
        COUNT(CASE WHEN cd_gender = 'M' THEN 1 END) AS male_count,
        COUNT(CASE WHEN cd_gender = 'F' THEN 1 END) AS female_count,
        SUM(COALESCE(hd_vehicle_count, 0)) AS total_vehicles,
        RANK() OVER (PARTITION BY ca_state ORDER BY SUM(COALESCE(hd_vehicle_count, 0)) DESC) AS state_rank
    FROM 
        customer_address
    LEFT JOIN 
        customer ON ca_address_sk = c_current_addr_sk
    LEFT JOIN 
        household_demographics ON c_current_hdemo_sk = hd_demo_sk
    LEFT JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY ca_address_sk, ca_city, ca_state
),
SalesData AS (
    SELECT
        ws_sold_date_sk,
        i_item_sk,
        SUM(ws_sales_price) AS total_sales,
        SUM(COALESCE(ws_ext_discount_amt, 0)) AS total_discount
    FROM 
        web_sales
    LEFT JOIN 
        item ON ws_item_sk = i_item_sk
    WHERE 
        ws_sales_price IS NOT NULL
    GROUP BY ws_sold_date_sk, i_item_sk
),
SalesSummary AS (
    SELECT
        d_year,
        SUM(total_sales) AS yearly_sales,
        SUM(total_discount) AS yearly_discount,
        MAX(total_sales) AS peak_sales
    FROM (
        SELECT
            D.d_year,
            S.total_sales,
            S.total_discount
        FROM 
            date_dim D
        JOIN 
            SalesData S ON D.d_date_sk = S.ws_sold_date_sk
    ) AS YearlySalesData
    GROUP BY d_year
)
SELECT
    A.ca_city,
    A.male_count,
    A.female_count,
    S.yearly_sales,
    S.yearly_discount,
    S.peak_sales,
    CASE 
        WHEN A.total_vehicles > 5 THEN 'High Vehicle Count'
        WHEN A.total_vehicles BETWEEN 1 AND 5 THEN 'Moderate Vehicle Count'
        ELSE 'Low Vehicle Count'
    END AS vehicle_count_category
FROM 
    AddressStats A
LEFT JOIN 
    SalesSummary S ON A.state_rank = 1
WHERE 
    A.male_count IS NOT NULL OR A.female_count IS NOT NULL
ORDER BY 
    A.ca_city ASC,
    S.yearly_sales DESC
LIMIT 100;
