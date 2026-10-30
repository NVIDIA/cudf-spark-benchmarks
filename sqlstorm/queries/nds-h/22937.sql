WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
), 
OrderSummary AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O' AND l.l_returnflag = 'N'
    GROUP BY o.o_orderkey
), 
TopRevenueOrders AS (
    SELECT 
        os.o_orderkey, 
        os.total_revenue,
        RANK() OVER (ORDER BY os.total_revenue DESC) AS rank_order
    FROM OrderSummary os
)
SELECT 
    p.p_partkey, 
    p.p_name, 
    p.p_brand,
    COALESCE(ps.ps_availqty, 0) AS available_quantity,
    SUM(CASE WHEN l.l_discount > 0.1 THEN l.l_extendedprice * l.l_discount ELSE 0 END) AS discount_revenue,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    r.r_name AS region_name
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN customer c ON o.o_custkey = c.c_custkey
LEFT JOIN nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE EXISTS (
    SELECT 1 
    FROM RankedSuppliers rs 
    WHERE rs.s_suppkey = ps.ps_suppkey 
    AND rs.rn <= 5 
    AND rs.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
)
GROUP BY 
    p.p_partkey, 
    p.p_name, 
    p.p_brand, 
    ps.ps_availqty, 
    r.r_name
HAVING 
    SUM(l.l_extendedprice) > 1000 
    OR SUM(COALESCE(l.l_discount, 0)) < 50
ORDER BY 
    unique_customers DESC, 
    discount_revenue DESC
LIMIT 10;
