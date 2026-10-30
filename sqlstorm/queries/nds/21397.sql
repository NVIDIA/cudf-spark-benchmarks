
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_net_paid) AS total_net_paid,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid) DESC) AS rank_per_customer
    FROM web_sales
    WHERE ws_ship_date_sk IS NOT NULL
    GROUP BY ws_bill_customer_sk
),
TopCustomers AS (
    SELECT 
        rc.ws_bill_customer_sk,
        rc.total_net_paid,
        ca.ca_city,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY rc.total_net_paid DESC) AS city_rank
    FROM RankedSales rc
    JOIN customer c ON rc.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE rc.rank_per_customer <= 5
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd_gender,
        cd_marital_status,
        cd_dep_count,
        cd_dep_employed_count,
        cd_dep_college_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesSummary AS (
    SELECT 
        tc.ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COALESCE(SUM(CASE WHEN cdem.cd_gender = 'F' THEN ws_ext_sales_price END), 0) AS female_sales,
        COALESCE(SUM(CASE WHEN cdem.cd_gender = 'M' THEN ws_ext_sales_price END), 0) AS male_sales
    FROM TopCustomers tc
    LEFT JOIN web_sales ws ON tc.ws_bill_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN CustomerDemographics cdem ON tc.ws_bill_customer_sk = cdem.c_customer_sk
    GROUP BY tc.ws_bill_customer_sk
)
SELECT 
    ss.ws_bill_customer_sk,
    ss.total_sales,
    ss.female_sales,
    ss.male_sales,
    ca.ca_city
FROM SalesSummary ss
JOIN customer_address ca ON ss.ws_bill_customer_sk = ca.ca_address_sk
WHERE ss.total_sales > (
    SELECT AVG(ss2.total_sales) 
    FROM SalesSummary ss2 
    WHERE ss2.total_sales IS NOT NULL
) OR ca.ca_city IS NULL
ORDER BY total_sales DESC, ca.ca_city;
