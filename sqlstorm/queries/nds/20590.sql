
WITH RankedReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        sr_return_quantity,
        sr_return_amt,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY sr_returned_date_sk DESC) AS rn
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 0
), 
HighValueReturns AS (
    SELECT 
        rr.sr_item_sk,
        SUM(rr.sr_return_amt) AS total_return_amt,
        COUNT(rr.sr_return_quantity) AS return_count
    FROM 
        RankedReturns rr
    WHERE 
        rr.rn > 5
    GROUP BY 
        rr.sr_item_sk
    HAVING 
        SUM(rr.sr_return_amt) > 5000
),
CustomerPurchases AS (
    SELECT 
        cs_bill_customer_sk AS customer_id,
        SUM(cs_net_paid_inc_tax) AS total_spent,
        COUNT(cs_order_number) AS purchase_count
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim WHERE d_current_month = 'Y')
    GROUP BY 
        cs_bill_customer_sk
),
TopCustomers AS (
    SELECT 
        cp.customer_id,
        cp.total_spent,
        DENSE_RANK() OVER (ORDER BY cp.total_spent DESC) AS rank
    FROM 
        CustomerPurchases cp
    WHERE 
        cp.total_spent > 1000
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ca.ca_address_id,
    COALESCE(tr.return_count, 0) AS returns_count,
    COALESCE(tr.total_return_amt, 0) AS total_returns,
    tc.rank AS customer_rank
FROM 
    customer c
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    HighValueReturns tr ON c.c_customer_sk = tr.sr_item_sk
LEFT JOIN 
    TopCustomers tc ON c.c_customer_sk = tc.customer_id
WHERE 
    (tc.rank IS NULL OR tc.rank <= 100)
    AND (c.c_birth_year IS NULL OR c.c_birth_year > 1980)
    AND (ca.ca_city LIKE '%York%' OR ca.ca_country IS NULL)
ORDER BY 
    total_returns DESC, 
    c.c_last_name ASC,
    c.c_first_name ASC
LIMIT 50;
