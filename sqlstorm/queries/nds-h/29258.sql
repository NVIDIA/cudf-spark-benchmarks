
WITH PartDetails AS (
    SELECT
        p.p_partkey,
        p.p_name,
        SUBSTRING(p.p_comment, 1, 10) AS short_comment,
        CONCAT(p.p_brand, ' ', p.p_type) AS brand_type
    FROM
        part p
),
SupplierDetails AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_phone,
        s.s_acctbal,
        CASE
            WHEN s.s_acctbal < 500 THEN 'Low'
            WHEN s.s_acctbal BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'High'
        END AS account_balance_category
    FROM
        supplier s
),
CustomerOrders AS (
    SELECT
        o.o_orderkey,
        c.c_custkey,
        c.c_name,
        COUNT(l.l_orderkey) AS line_items,
        SUM(l.l_extendedprice) AS total_price
    FROM
        orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY
        o.o_orderkey, c.c_custkey, c.c_name
)
SELECT
    pd.p_partkey,
    pd.p_name,
    sd.s_name AS supplier_name,
    sd.account_balance_category,
    co.c_name AS customer_name,
    co.line_items,
    co.total_price,
    TRIM(CONCAT(pd.short_comment, ' | ', pd.brand_type)) AS processed_info
FROM
    PartDetails pd
JOIN partsupp ps ON pd.p_partkey = ps.ps_partkey
JOIN SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
JOIN CustomerOrders co ON co.o_orderkey = (
    SELECT o.o_orderkey
    FROM orders o
    ORDER BY o.o_orderdate DESC
    LIMIT 1
)
WHERE
    sd.s_name LIKE 'Supplier%'
ORDER BY
    co.total_price DESC
LIMIT 10;
