WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nation_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal > (
        SELECT AVG(s_acctbal)
        FROM supplier
        WHERE s_acctbal IS NOT NULL
    )
),
PartSupplyDetails AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, ps.ps_supplycost,
           p.p_name, p.p_brand, p.p_container
    FROM partsupp ps
    LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_retailprice > 100.00
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_totalprice, c.c_mktsegment, l.l_discount,
           ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS rn
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O' AND l.l_returnflag = 'N'
),
FilteredOrders AS (
    SELECT od.o_orderkey, od.o_totalprice, od.c_mktsegment
    FROM OrderDetails od
    WHERE od.rn <= 5
)
SELECT 
    pd.p_name, pd.p_brand, pd.p_container, 
    sd.s_name AS supplier_name, sd.nation_name,
    SUM(ld.l_quantity) AS total_quantity, 
    SUM(ld.l_extendedprice * (1 - ld.l_discount)) AS revenue
FROM PartSupplyDetails pd
JOIN SupplierDetails sd ON pd.ps_suppkey = sd.s_suppkey
JOIN lineitem ld ON pd.ps_partkey = ld.l_partkey
JOIN FilteredOrders fo ON ld.l_orderkey = fo.o_orderkey
GROUP BY pd.p_name, pd.p_brand, pd.p_container, sd.s_name, sd.nation_name
HAVING SUM(ld.l_quantity) > 100
ORDER BY revenue DESC;
