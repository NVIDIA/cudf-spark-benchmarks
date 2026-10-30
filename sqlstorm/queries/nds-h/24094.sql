
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank_acctbal
    FROM supplier s
),
MaxSupplier AS (
    SELECT
        n.n_nationkey, 
        n.n_name, 
        MAX(rs.s_acctbal) AS max_acctbal
    FROM nation n
    JOIN RankedSuppliers rs ON n.n_nationkey = rs.s_suppkey
    GROUP BY n.n_nationkey, n.n_name
),
OrderStats AS (
    SELECT 
        o.o_orderkey, 
        o.o_totalprice, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        CASE 
            WHEN o.o_orderstatus = 'F' THEN 'Finalized'
            WHEN o.o_orderstatus = 'P' THEN 'Pending'
            ELSE 'Unknown' 
        END AS order_status
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_totalprice, o.o_orderstatus
)
SELECT 
    p.p_partkey, 
    p.p_name, 
    ps.ps_availqty, 
    ps.ps_supplycost,
    COALESCE(SUM(l.l_quantity), 0) AS total_ordered,
    CASE 
        WHEN ps.ps_availqty > 0 THEN 'Available'
        WHEN ps.ps_availqty IS NULL THEN 'Unknown'
        ELSE 'Out of Stock'
    END AS availability,
    (SELECT COUNT(DISTINCT o.o_orderkey) 
     FROM orders o 
     WHERE o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
       AND o.o_orderstatus IN ('F', 'P')) AS order_count,
    ns.max_acctbal AS max_supplier_acctbal
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN MaxSupplier ns ON ps.ps_suppkey = ns.n_nationkey
WHERE p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_container LIKE '%BOX%') 
  AND (p.p_retailprice < 50)
GROUP BY p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost, ns.max_acctbal
HAVING COALESCE(SUM(l.l_quantity), 0) > COALESCE((SELECT AVG(l2.l_quantity) FROM lineitem l2), 0)
ORDER BY p.p_name DESC, total_ordered ASC;
