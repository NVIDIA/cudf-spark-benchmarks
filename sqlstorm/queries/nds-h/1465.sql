WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rn
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
),
SupplierPartStats AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(l.l_quantity) AS total_quantity,
        AVG(l.l_extendedprice) AS avg_extended_price
    FROM partsupp ps
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ns.n_name AS nation_name
    FROM supplier s
    JOIN nation ns ON s.s_nationkey = ns.n_nationkey
    WHERE s.s_acctbal > (
        SELECT AVG(s2.s_acctbal) 
        FROM supplier s2 
        WHERE s2.s_nationkey = s.s_nationkey
    )
)
SELECT 
    r.o_orderkey,
    r.o_totalprice,
    r.o_orderdate,
    r.c_name,
    r.c_acctbal,
    sp.total_quantity,
    sp.avg_extended_price,
    fs.nation_name,
    COALESCE(fs.s_acctbal, 0) AS supplier_acctbal
FROM RankedOrders r
LEFT JOIN SupplierPartStats sp ON r.o_orderkey = sp.ps_partkey
LEFT JOIN FilteredSuppliers fs ON sp.ps_suppkey = fs.s_suppkey
WHERE r.rn <= 5 
AND r.o_orderdate > '1996-01-01'
ORDER BY r.o_orderdate DESC, r.o_totalprice DESC;