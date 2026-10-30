WITH Ranked_Suppliers AS (
    SELECT s.s_suppkey,
           s.s_name,
           s.s_acctbal,
           DENSE_RANK() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal IS NOT NULL
),
High_Value_Orders AS (
    SELECT o.o_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O' 
      AND l.l_returnflag = 'N'
    GROUP BY o.o_orderkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
),
Supplier_Count AS (
    SELECT ps.ps_partkey,
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM partsupp ps
    JOIN Ranked_Suppliers rs ON ps.ps_suppkey = rs.s_suppkey
    GROUP BY ps.ps_partkey
),
Filtered_Parts AS (
    SELECT p.p_partkey,
           p.p_name,
           p.p_brand,
           p.p_retailprice,
           COALESCE(su.supplier_count, 0) AS supplier_count
    FROM part p
    LEFT JOIN Supplier_Count su ON p.p_partkey = su.ps_partkey
    WHERE p.p_retailprice > (
        SELECT AVG(p2.p_retailprice)
        FROM part p2
    )
)
SELECT fp.p_partkey,
       fp.p_name,
       fp.p_brand,
       fp.p_retailprice,
       fp.supplier_count,
       COUNT(DISTINCT hvo.o_orderkey) AS high_value_orders
FROM Filtered_Parts fp
LEFT JOIN High_Value_Orders hvo ON fp.p_partkey = hvo.o_orderkey
GROUP BY fp.p_partkey, 
         fp.p_name, 
         fp.p_brand, 
         fp.p_retailprice, 
         fp.supplier_count
HAVING SUM(fp.supplier_count) > 0
ORDER BY fp.p_retailprice DESC, 
         high_value_orders DESC
LIMIT 10;
