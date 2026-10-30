WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
),
SupplierCost AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        COALESCE(SC.total_supply_cost, 0) AS supply_cost
    FROM 
        part p
    LEFT JOIN 
        SupplierCost SC ON p.p_partkey = SC.ps_partkey
    WHERE 
        p.p_retailprice - COALESCE(SC.total_supply_cost, 0) > 100
)
SELECT 
    RO.o_orderkey,
    RO.o_orderdate,
    HVP.p_partkey,
    HVP.p_name,
    HVP.p_retailprice,
    HVP.supply_cost
FROM 
    RankedOrders RO
JOIN 
    lineitem L ON RO.o_orderkey = L.l_orderkey
JOIN 
    HighValueParts HVP ON L.l_partkey = HVP.p_partkey
WHERE 
    RO.order_rank = 1
    AND (HVP.supply_cost IS NOT NULL OR HVP.supply_cost > 50)
ORDER BY 
    RO.o_orderdate DESC, 
    HVP.p_retailprice DESC;
