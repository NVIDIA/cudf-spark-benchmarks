
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_bill_customer_sk,
        ws_sales_price,
        ws_quantity,
        ws_sales_price * ws_quantity AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY ws_sales_price DESC) AS sales_rank,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY ws_quantity DESC) AS quantity_rank
    FROM web_sales
    WHERE ws_sales_price IS NOT NULL AND ws_quantity > 0
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        SUM(rs.total_sales) AS total_spent
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN RankedSales rs ON c.c_customer_sk = rs.ws_bill_customer_sk
    WHERE EXISTS (
        SELECT 1 
        FROM RankedSales sub
        WHERE sub.ws_bill_customer_sk = c.c_customer_sk AND sub.sales_rank <= 3
    )
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, ca.ca_city
    HAVING SUM(rs.total_sales) >= 1000
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM customer_demographics cd
    WHERE cd.cd_purchase_estimate IS NOT NULL
),
CombinedStats AS (
    SELECT 
        tc.c_customer_sk,
        tc.c_first_name,
        tc.c_last_name,
        tc.ca_city,
        COALESCE(d.cd_gender, 'Unknown') AS gender,
        COALESCE(d.cd_marital_status, 'Unknown') AS marital_status,
        COALESCE(d.cd_purchase_estimate, 0) AS purchase_estimate,
        tc.total_spent,
        ROW_NUMBER() OVER (ORDER BY tc.total_spent DESC) AS customer_rank
    FROM TopCustomers tc
    LEFT JOIN CustomerDemographics d ON tc.c_customer_sk = d.cd_demo_sk
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    c.ca_city,
    COALESCE(c.gender, 'Not Specified') AS gender_specified,
    c.marital_status,
    c.total_spent,
    (CASE 
        WHEN c.total_spent BETWEEN 1000 AND 5000 THEN 'Low spender'
        WHEN c.total_spent BETWEEN 5001 AND 10000 THEN 'Medium spender'
        ELSE 'High spender'
    END) AS spending_category,
    (SELECT COUNT(*) FROM CombinedStats WHERE total_spent > c.total_spent) AS rank_position
FROM CombinedStats c
WHERE c.customer_rank <= 10
ORDER BY c.total_spent DESC
LIMIT 5 OFFSET 5;
