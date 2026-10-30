
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
    WHERE o.o_orderstatus = 'O'
),
CustomerDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        n.n_name AS nation_name,
        RANK() OVER (PARTITION BY n.n_name ORDER BY c.c_acctbal DESC) AS rank_by_nation
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > 1000
),
SupplierPartDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
LineItemSummary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_price,
        CASE 
            WHEN SUM(l.l_discount) > 0.5 THEN 'High Discount'
            ELSE 'Normal Discount'
        END AS discount_category
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT 
    cd.c_name,
    cd.nation_name,
    ro.o_orderkey,
    SUM(l.total_line_price) AS total_order_value,
    spd.total_supply_cost,
    COALESCE(spd.total_supply_cost, 0) AS supply_cost_or_zero,
    cd.rank_by_nation
FROM RankedOrders ro
JOIN CustomerDetails cd ON ro.o_custkey = cd.c_custkey
LEFT JOIN LineItemSummary l ON ro.o_orderkey = l.l_orderkey
FULL OUTER JOIN SupplierPartDetails spd ON spd.s_suppkey = (
    SELECT ps.ps_suppkey 
    FROM partsupp ps 
    WHERE ps.ps_partkey = (
        SELECT p.p_partkey 
        FROM part p 
        WHERE p.p_brand = 'Brand#45' 
        ORDER BY p.p_retailprice DESC 
        LIMIT 1
    ) 
    LIMIT 1
)
WHERE cd.rank_by_nation < 5
GROUP BY cd.c_name, cd.nation_name, ro.o_orderkey, spd.total_supply_cost, cd.rank_by_nation
HAVING SUM(l.total_line_price) IS NOT NULL AND SUM(l.total_line_price) > 1000
ORDER BY cd.nation_name, total_order_value DESC;
