
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal > 5000
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS part_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O' AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY o.o_orderkey
),
SupplierAndParts AS (
    SELECT 
        ps.ps_partkey,
        s.s_name AS supplier_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        p.p_name AS part_name,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS rank
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE ps.ps_availqty > 100
)
SELECT 
    COALESCE(os.o_orderkey, 0) AS order_id,
    p.p_partkey AS part_id,
    p.p_name AS part_name,
    ss.supplier_name,
    SUM(os.total_revenue) AS total_order_revenue,
    AVG(ss.ps_supplycost) AS avg_supply_cost
FROM partsupp ps
LEFT JOIN SupplierAndParts ss ON ps.ps_partkey = ss.ps_partkey AND ss.rank = 1
LEFT JOIN OrderSummary os ON os.o_orderkey = ps.ps_partkey
JOIN part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN RankedSuppliers r ON ss.supplier_name = r.s_name
WHERE p.p_size < 30
GROUP BY os.o_orderkey, p.p_partkey, p.p_name, ss.supplier_name
HAVING SUM(os.total_revenue) > 10000
ORDER BY total_order_revenue DESC, supplier_name;
