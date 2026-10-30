WITH SupplierInfo AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nation_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, c.c_name, c.c_mktsegment
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_totalprice > 10000 AND o.o_orderstatus = 'F'
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, ps.ps_supplycost, ps.ps_availqty
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE ps.ps_availqty > 20
)
SELECT 
    si.nation_name,
    SUM(hv.o_totalprice) AS total_order_value,
    COUNT(DISTINCT hv.o_orderkey) AS total_orders,
    COUNT(DISTINCT pd.p_partkey) AS total_parts_supplied
FROM 
    SupplierInfo si
JOIN 
    lineitem l ON si.s_suppkey = l.l_suppkey
JOIN 
    HighValueOrders hv ON l.l_orderkey = hv.o_orderkey
JOIN 
    PartDetails pd ON l.l_partkey = pd.p_partkey
GROUP BY 
    si.nation_name
ORDER BY 
    total_order_value DESC
LIMIT 10;
