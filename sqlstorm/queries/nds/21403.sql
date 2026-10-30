WITH RankedReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        COUNT(*) AS return_count,
        DENSE_RANK() OVER (PARTITION BY sr_item_sk ORDER BY SUM(sr_return_amt) DESC) AS rank_amt,
        SUM(sr_return_quantity) AS total_returned_qty
    FROM store_returns
    GROUP BY sr_returned_date_sk, sr_item_sk
),
                    CustomerSales AS (
    SELECT 
        c.c_customer_id,
        COALESCE(SUM(ws_ext_sales_price), 0) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        MAX(d.d_date) AS last_purchase_date
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY c.c_customer_id
)
SELECT 
    ca.ca_address_id,
    cd.cd_gender,
    cs.c_customer_id,
    cs.total_sales,
    cs.order_count,
    cs.last_purchase_date,
    CASE 
        WHEN cs.total_sales = 0 THEN 'No Sales'
        WHEN cs.order_count > 10 THEN 'Frequent Buyer'
        ELSE 'Occasional Buyer'
    END AS customer_type,
    COALESCE(rr.return_count, 0) AS return_count,
    rr.total_returned_qty,
    RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
FROM customer_address ca
JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN CustomerSales cs ON c.c_customer_id = cs.c_customer_id
LEFT JOIN RankedReturns rr ON rr.sr_item_sk = (SELECT MAX(i_item_sk) FROM item) 
WHERE COALESCE(c.c_birth_year, 1900) > 1950 
  AND (cd.cd_marital_status = 'M' OR cd.cd_marital_status IS NULL)
ORDER BY customer_type DESC, cs.total_sales DESC;