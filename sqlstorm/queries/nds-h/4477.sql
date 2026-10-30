WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),

TotalOrderValue AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'N'
    GROUP BY o.o_orderkey
),

ActiveCustomers AS (
    SELECT 
        DISTINCT c.c_custkey, 
        c.c_name, 
        c.c_acctbal 
    FROM customer c 
    WHERE c.c_acctbal > 1000 AND c.c_mktsegment = 'BUILDING'
),

SupplierInfo AS (
    SELECT 
        s.s_nationkey,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        AVG(s.s_acctbal) AS avg_acctbal
    FROM rankedSuppliers rs
    LEFT JOIN supplier s ON rs.s_suppkey = s.s_suppkey
    GROUP BY s.s_nationkey
)

SELECT 
    n.n_name,
    si.supplier_count,
    si.avg_acctbal,
    ac.c_name,
    ac.c_acctbal,
    tot.total_value
FROM nation n
LEFT JOIN SupplierInfo si ON n.n_nationkey = si.s_nationkey
FULL OUTER JOIN ActiveCustomers ac ON ac.c_custkey = si.supplier_count
JOIN TotalOrderValue tot ON tot.o_orderkey = ac.c_custkey
WHERE si.avg_acctbal IS NOT NULL
  AND (si.supplier_count > 5 OR ac.c_acctbal IS NULL)
ORDER BY n.n_name, ac.c_name;
