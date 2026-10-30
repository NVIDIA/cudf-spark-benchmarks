WITH RankedParts AS (
    SELECT p.p_partkey, 
           p.p_name, 
           p.p_brand, 
           p.p_retailprice,
           RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) as PriceRank
    FROM part p
    WHERE p.p_retailprice > 0
),
SuppliersByRegion AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           n.n_name AS nation_name, 
           r.r_name AS region_name,
           s.s_acctbal
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
CustomerOrders AS (
    SELECT c.c_custkey, 
           COUNT(o.o_orderkey) AS total_orders, 
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
OrderLineSummary AS (
    SELECT l.l_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_price,
           COUNT(CASE WHEN l.l_returnflag = 'Y' THEN 1 END) AS return_count
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT ps.ps_partkey, 
       rp.p_name, 
       rp.p_brand, 
       rp.p_retailprice, 
       sr.region_name, 
       csr.total_orders, 
       csr.total_spent,
       ols.total_line_price,
       ols.return_count
FROM partsupp ps
JOIN RankedParts rp ON ps.ps_partkey = rp.p_partkey AND rp.PriceRank <= 5
JOIN SuppliersByRegion sr ON ps.ps_suppkey = sr.s_suppkey
LEFT JOIN CustomerOrders csr ON sr.s_suppkey = csr.c_custkey
LEFT JOIN OrderLineSummary ols ON ols.l_orderkey = ps.ps_partkey
WHERE sr.s_acctbal BETWEEN 1000.00 AND 5000.00
ORDER BY rp.p_retailprice DESC, sr.region_name;
