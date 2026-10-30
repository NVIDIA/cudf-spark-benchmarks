
WITH RankedParts AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_retailprice, 
           ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank_by_price
    FROM part p
), 
NationDetails AS (
    SELECT n.n_nationkey, n.n_name, r.r_name AS region_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
), 
SupplierStats AS (
    SELECT s.s_suppkey, SUM(ps.ps_availqty) AS total_avail_qty, 
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey 
    GROUP BY s.s_suppkey
), 
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS total_orders, 
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey 
    GROUP BY c.c_custkey, c.c_name
), 
LineItemStats AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    WHERE l.l_returnflag = 'N' 
    GROUP BY l.l_orderkey
)

SELECT 
    nd.n_name, 
    COUNT(DISTINCT rp.p_partkey) AS part_count, 
    SUM(ss.total_avail_qty) AS total_available_quantity,
    CASE WHEN SUM(co.total_spent) IS NULL THEN 'No Orders' ELSE CAST(SUM(co.total_spent) AS STRING) END AS customer_spending,
    STRING_AGG(DISTINCT rp.p_name, ', ') AS expensive_parts,
    MAX(l.total_revenue) AS max_order_revenue
FROM RankedParts rp
JOIN SupplierStats ss ON rp.p_partkey = ss.s_suppkey
FULL OUTER JOIN NationDetails nd ON ss.s_suppkey = nd.n_nationkey
LEFT JOIN CustomerOrders co ON nd.n_nationkey = co.c_custkey
LEFT JOIN LineItemStats l ON co.c_custkey = l.l_orderkey
WHERE rp.rank_by_price <= 3
AND (nd.n_name IS NOT NULL OR nd.region_name IS NULL)
GROUP BY nd.n_name
ORDER BY part_count DESC, customer_spending DESC NULLS LAST;
