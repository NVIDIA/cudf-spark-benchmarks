WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) as rank,
        n.n_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 0
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY o.o_orderkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
CustomerRanked AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        DENSE_RANK() OVER (ORDER BY c.c_acctbal DESC) AS cust_rank
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL
),
FilteredPart AS (
    SELECT 
        p.p_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
    HAVING COUNT(DISTINCT ps.ps_suppkey) > 2
)
SELECT 
    c.c_name,
    AVG(s.s_acctbal) AS avg_supp_acctbal,
    SUM(hv.total_revenue) AS total_revenue,
    COUNT(DISTINCT fp.p_partkey) AS part_count
FROM CustomerRanked c
JOIN RankedSuppliers s ON c.c_custkey = s.s_suppkey
JOIN HighValueOrders hv ON c.c_custkey = hv.o_orderkey
LEFT JOIN FilteredPart fp ON fp.supplier_count = s.rank
WHERE c.cust_rank <= 10 AND s.rank = 1
GROUP BY c.c_name
HAVING COUNT(fp.p_partkey) > 0
ORDER BY avg_supp_acctbal DESC, total_revenue DESC
LIMIT 50;