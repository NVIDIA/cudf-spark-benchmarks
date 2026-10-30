WITH RankedParts AS (
    SELECT
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rnk
    FROM part p
    WHERE p.p_size > 10
),
SupplierSales AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE l.l_shipdate >= '1997-01-01'
    GROUP BY s.s_suppkey, s.s_name
),
HighValueCustomers AS (
    SELECT
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O' 
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 10000
)
SELECT
    r.p_partkey,
    r.p_name,
    r.p_retailprice,
    COALESCE(s.total_sales, 0) AS total_supplier_sales,
    COALESCE(h.total_spent, 0) AS total_customer_spent,
    CASE 
        WHEN r.rnk <= 5 THEN 'Top 5'
        ELSE 'Other'
    END AS part_ranking
FROM RankedParts r
LEFT JOIN SupplierSales s ON r.p_partkey = s.s_suppkey
LEFT JOIN HighValueCustomers h ON s.s_suppkey = h.c_custkey
WHERE r.p_retailprice BETWEEN 50 AND 200
ORDER BY r.p_retailprice DESC, part_ranking;