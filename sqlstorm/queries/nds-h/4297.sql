WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderpriority,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
),
PartSupplierData AS (
    SELECT 
        ps.ps_partkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey, s.s_name
)
SELECT 
    p.p_name,
    COUNT(DISTINCT lo.l_orderkey) AS total_orders,
    AVG(lo.l_extendedprice) AS average_price,
    COALESCE(psd.total_supply_cost, 0) AS total_supplier_cost,
    r.r_name AS region_name
FROM part p
LEFT JOIN lineitem lo ON p.p_partkey = lo.l_partkey
LEFT JOIN PartSupplierData psd ON p.p_partkey = psd.ps_partkey
JOIN supplier s ON psd.s_name = s.s_name
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE p.p_retailprice > 20.00
GROUP BY p.p_name, r.r_name, psd.total_supply_cost
HAVING COUNT(DISTINCT lo.l_orderkey) > 5 
   OR AVG(lo.l_extendedprice) > (SELECT AVG(l.l_extendedprice) 
                                  FROM lineitem l 
                                  WHERE l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31')
ORDER BY total_orders DESC, average_price ASC;