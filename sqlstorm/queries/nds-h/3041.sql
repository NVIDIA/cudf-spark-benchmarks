WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS price_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
),
SupplierAvailability AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
TopProducts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        COALESCE(SA.total_avail_qty, 0) AS available_quantity,
        COALESCE(SA.total_supply_cost, 0) AS supply_cost
    FROM 
        part p
    LEFT JOIN 
        SupplierAvailability SA ON p.p_partkey = SA.ps_partkey
    WHERE 
        p.p_retailprice > 50.00
),
HighValueOrders AS (
    SELECT 
        r.o_orderkey,
        r.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(DISTINCT l.l_partkey) AS distinct_parts
    FROM 
        RankedOrders r
    JOIN 
        lineitem l ON r.o_orderkey = l.l_orderkey
    WHERE 
        r.price_rank <= 5
    GROUP BY 
        r.o_orderkey, r.o_orderdate
)
SELECT 
    TV.p_partkey,
    TV.p_name,
    TV.p_brand,
    TV.available_quantity,
    TV.supply_cost,
    HVO.total_order_value,
    HVO.distinct_parts
FROM 
    TopProducts TV
FULL OUTER JOIN 
    HighValueOrders HVO ON TV.p_partkey = HVO.o_orderkey
WHERE 
    (TV.available_quantity IS NOT NULL OR HVO.total_order_value IS NOT NULL)
    AND (TV.available_quantity < 100 OR HVO.total_order_value > 5000)
ORDER BY 
    TV.p_partkey, HVO.total_order_value DESC;
