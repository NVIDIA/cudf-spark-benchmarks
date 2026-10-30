WITH RankedParts AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_retailprice, 
           ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
    WHERE p.p_retailprice > 100.00
), SupplierRegions AS (
    SELECT s.s_suppkey, s.s_name, n.n_name AS nation_name, r.r_name AS region_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
), CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice, o.o_orderdate
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
), LineItemDetails AS (
    SELECT li.l_orderkey, SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue
    FROM lineitem li
    WHERE li.l_shipdate >= cast('1998-10-01' as date) - INTERVAL '30 days'
    GROUP BY li.l_orderkey
)
SELECT cr.c_name, sr.nation_name, sr.region_name, 
       rp.p_name, rp.p_retailprice, 
       COALESCE(ld.total_revenue, 0) AS last_month_revenue
FROM CustomerOrders cr
JOIN SupplierRegions sr ON cr.c_custkey % 100 = sr.s_suppkey % 100
JOIN RankedParts rp ON sr.s_suppkey % 10 = rp.p_partkey % 10
LEFT JOIN LineItemDetails ld ON cr.o_orderkey = ld.l_orderkey
WHERE rp.price_rank <= 5
ORDER BY last_month_revenue DESC, rp.p_retailprice DESC
LIMIT 50;