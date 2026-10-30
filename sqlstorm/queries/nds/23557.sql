
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
    HAVING 
        SUM(ws_net_paid_inc_tax) > 1000
),
CustomerAddress AS (
    SELECT 
        ca_address_sk,
        ca_zip,
        ca_city,
        ca_state,
        CASE 
            WHEN ca_city IS NULL THEN 'Unknown City'
            ELSE ca_city 
        END AS city_safe
    FROM 
        customer_address
    WHERE 
        ca_state IN ('CA', 'NY')
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        CASE 
            WHEN d.d_holiday = 'Y' THEN 'Holiday Shopper'
            ELSE 'Regular Shopper'
        END AS shopper_type,
        coalesce(ADDRESS.city_safe, 'No Address') AS customer_city
    FROM 
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN CustomerAddress ADDRESS ON c.c_current_addr_sk = ADDRESS.ca_address_sk
    LEFT JOIN date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND (cd.cd_marital_status = 'M' OR cd.cd_purchase_estimate > 500) 
        AND EXISTS (
            SELECT 1 
            FROM RankedSales rs 
            WHERE c.c_customer_sk = rs.ws_bill_customer_sk 
            AND rs.sales_rank <= 5
        )
)
SELECT 
    hvc.c_customer_sk,
    hvc.c_first_name,
    hvc.c_last_name,
    COUNT(DISTINCT hvc.shopper_type) AS shopper_frequency,
    AVG(r.total_sales) AS avg_sales_amount,
    MAX(CASE WHEN r.sales_rank IS NULL THEN 0 ELSE r.sales_rank END) AS max_sales_rank
FROM 
    HighValueCustomers hvc
LEFT JOIN RankedSales r ON hvc.c_customer_sk = r.ws_bill_customer_sk
GROUP BY 
    hvc.c_customer_sk, 
    hvc.c_first_name, 
    hvc.c_last_name
HAVING 
    COUNT(DISTINCT hvc.shopper_type) > 1 
    AND AVG(COALESCE(r.total_sales, 0)) > 1000
ORDER BY 
    avg_sales_amount DESC, 
    hvc.c_first_name;
