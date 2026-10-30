WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_name,
        o.o_totalprice,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate >= '1997-01-01'
),

SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),

PartStats AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COUNT(ps.ps_suppkey) AS supply_count,
        AVG(p.p_retailprice) AS avg_retail_price
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
)

SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.c_name,
    ps.p_name,
    ps.avg_retail_price,
    sd.total_supply_cost,
    CASE 
        WHEN ro.order_rank = 1 THEN 'Highest Order'
        ELSE 'Regular Order' 
    END AS order_type
FROM RankedOrders ro
JOIN lineitem l ON ro.o_orderkey = l.l_orderkey
JOIN PartStats ps ON l.l_partkey = ps.p_partkey
JOIN SupplierDetails sd ON l.l_suppkey = sd.s_suppkey
WHERE ps.supply_count > 5
  AND sd.total_supply_cost IS NOT NULL
  AND ro.o_totalprice > (SELECT AVG(o_totalprice) FROM orders)
ORDER BY ro.o_orderdate DESC, ro.o_totalprice DESC;