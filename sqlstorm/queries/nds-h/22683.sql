WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        p.p_brand,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank
    FROM part p
    WHERE p.p_size IN (SELECT DISTINCT ps.ps_availqty FROM partsupp ps WHERE ps.ps_supplycost > 100)
),
OrderInfo AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        COUNT(l.l_orderkey) AS line_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey, o.o_orderdate
),
CustomerSummary AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT 
    R.p_partkey,
    R.p_name,
    COALESCE(S.order_count, 0) AS order_count,
    COALESCE(S.total_spent, 0) AS total_spent,
    O.line_count,
    O.total_revenue,
    CASE 
        WHEN total_revenue IS NULL THEN 'No Revenue'
        WHEN total_revenue > 1000 THEN 'High Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category
FROM RankedParts R
LEFT JOIN CustomerSummary S ON S.order_count > R.rank
LEFT JOIN OrderInfo O ON O.o_orderkey = (SELECT MAX(o2.o_orderkey) FROM orders o2 WHERE o2.o_orderdate <= cast('1998-10-01' as date))
WHERE R.rank = 1
    OR R.p_name LIKE '%widget%'
ORDER BY R.p_retailprice DESC, revenue_category
LIMIT 10;