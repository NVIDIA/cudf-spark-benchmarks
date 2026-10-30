
WITH RankedSupplier AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        p.p_size
    FROM part p
    WHERE p.p_retailprice > 100.00
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= DATE '1997-01-01'
    GROUP BY c.c_custkey
),
PartSupplierInfo AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        (SELECT AVG(l.l_extendedprice * (1 - l.l_discount))
         FROM lineitem l
         WHERE l.l_partkey = ps.ps_partkey) AS avg_sales_price
    FROM partsupp ps
)
SELECT 
    nc.n_name AS nation_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    ARRAY_AGG(DISTINCT fp.p_name) AS products,
    MAX(psi.avg_sales_price) AS max_avg_sales_price
FROM lineitem l
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
JOIN nation nc ON c.c_nationkey = nc.n_nationkey
LEFT JOIN FilteredParts fp ON l.l_partkey = fp.p_partkey
LEFT JOIN PartSupplierInfo psi ON psi.ps_partkey = l.l_partkey
WHERE l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
  AND nc.n_name IN (SELECT n.n_name FROM nation n WHERE n.n_regionkey = 1)
  AND (fp.p_size IS NULL OR fp.p_size > 20)
GROUP BY nc.n_name
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) IS NOT NULL
ORDER BY total_revenue DESC;
