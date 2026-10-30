WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        c.c_name, 
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
),
SupplierAggregates AS (
    SELECT 
        ps.ps_partkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
PartDetails AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        p.p_retailprice, 
        COALESCE(sa.total_supply_cost, 0) AS total_supply_cost, 
        COALESCE(sa.supplier_count, 0) AS supplier_count
    FROM part p
    LEFT JOIN SupplierAggregates sa ON p.p_partkey = sa.ps_partkey
)
SELECT 
    ro.o_orderkey, 
    ro.o_orderdate, 
    ro.o_totalprice, 
    pd.p_name, 
    pd.p_brand, 
    pd.p_retailprice, 
    pd.total_supply_cost, 
    pd.supplier_count
FROM RankedOrders ro
JOIN lineitem l ON ro.o_orderkey = l.l_orderkey
JOIN PartDetails pd ON l.l_partkey = pd.p_partkey
WHERE ro.order_rank = 1
ORDER BY ro.o_orderdate DESC, ro.o_totalprice DESC
LIMIT 100;
