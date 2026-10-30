
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE s.s_acctbal IS NOT NULL
),
CustomerOrderDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_totalprice,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice
)
SELECT 
    r.r_name AS region_name,
    SUM(COALESCE(cd.total_revenue, 0)) AS total_revenue_by_region,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    COUNT(DISTINCT rs.s_suppkey) AS top_suppliers
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN RankedSuppliers rs ON s.s_suppkey = rs.s_suppkey AND rs.rn = 1
LEFT JOIN CustomerOrderDetails cd ON s.s_suppkey = cd.o_orderkey
LEFT JOIN customer c ON s.s_suppkey = c.c_custkey -- Added join to link customer correctly
WHERE r.r_comment LIKE '%excellent%'
GROUP BY r.r_name
ORDER BY total_revenue_by_region DESC, unique_customers DESC
LIMIT 10;
