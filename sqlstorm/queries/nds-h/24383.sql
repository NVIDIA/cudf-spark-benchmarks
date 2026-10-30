WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s_nationkey ORDER BY s_acctbal DESC) AS rank
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
), SupplierPrices AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, ps.ps_supplycost,
           (ps.ps_supplycost * 1.2) AS adjusted_cost
    FROM partsupp ps
    WHERE ps.ps_availqty > (
        SELECT AVG(ps2.ps_availqty)
        FROM partsupp ps2
        WHERE ps2.ps_partkey = ps.ps_partkey
    )
), OrderDetails AS (
    SELECT o.o_orderkey, o.o_totalprice, l.l_partkey, l.l_quantity, l.l_discount,
           (l.l_extendedprice * (1 - l.l_discount)) AS net_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
), ExpensiveProducts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice,
           CASE 
               WHEN p.p_retailprice IS NULL THEN 'Price Unknown' 
               WHEN p.p_retailprice > 500 THEN 'Expensive' 
               ELSE 'Affordable' 
           END AS price_category
    FROM part p
    WHERE p.p_retailprice IS NOT NULL
)
SELECT rp.s_name, ep.price_category, ep.p_name, 
       SUM(od.net_price) AS total_ordered_value,
       MAX(sp.adjusted_cost) AS max_supplier_cost
FROM RankedSuppliers rp
JOIN SupplierPrices sp ON rp.s_suppkey = sp.ps_suppkey
JOIN OrderDetails od ON sp.ps_partkey = od.l_partkey
JOIN ExpensiveProducts ep ON ep.p_partkey = sp.ps_partkey
WHERE rp.rank <= 5
GROUP BY rp.s_name, ep.price_category, ep.p_name
HAVING SUM(od.net_price) > 1000
ORDER BY total_ordered_value DESC, rp.s_name ASC;
