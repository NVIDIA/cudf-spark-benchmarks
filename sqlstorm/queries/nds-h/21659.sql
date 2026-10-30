
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
),
PartStats AS (
    SELECT 
        p.p_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        SUM(ps.ps_availqty) AS total_availqty
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value,
        COUNT(DISTINCT l.l_orderkey) AS line_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1997-01-01' 
      AND o.o_orderstatus IN ('F', 'O')
    GROUP BY o.o_orderkey, o.o_orderstatus
),
FilteredCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        RANK() OVER (ORDER BY c.c_acctbal DESC) AS cust_rank
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL
),
FinalAggregation AS (
    SELECT 
        ps.p_partkey,
        ps.supplier_count,
        ps.total_availqty,
        ho.o_orderkey,
        ho.total_value,
        ho.line_count,
        fc.c_custkey,
        fc.c_name
    FROM PartStats ps
    LEFT JOIN HighValueOrders ho ON ho.line_count > 5 
    LEFT JOIN FilteredCustomers fc ON fc.cust_rank <= 10
    WHERE ps.supplier_count > 2 
      AND (ps.total_availqty IS NULL OR ps.total_availqty > 100)
)
SELECT 
    f.p_partkey,
    f.total_availqty,
    f.total_value,
    COALESCE(f.c_name, 'No Customer') AS customer_name,
    COALESCE(rs.s_name, 'Unknown Supplier') AS supplier_name
FROM FinalAggregation f
LEFT JOIN RankedSuppliers rs ON f.supplier_count = rs.rank
WHERE (f.total_value IS NOT NULL OR f.total_value > (SELECT AVG(total_value) FROM HighValueOrders))
  AND f.total_value BETWEEN (SELECT MAX(total_value) FROM HighValueOrders WHERE total_value < 5000) 
                         AND (SELECT MIN(total_value) FROM HighValueOrders WHERE total_value > 100)
ORDER BY f.total_value DESC, f.p_partkey ASC;
