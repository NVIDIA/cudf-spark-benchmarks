WITH SupplyCosts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        COALESCE(SC.total_supply_cost, 0) AS total_supply_cost
    FROM 
        part p
    LEFT JOIN 
        SupplyCosts SC ON p.p_partkey = SC.ps_partkey
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2) 
        AND (p.p_container IS NULL OR p.p_container <> 'BOX')
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey
)
SELECT 
    HVP.p_partkey,
    HVP.p_name,
    HVP.p_brand,
    C.order_count,
    C.avg_order_value,
    HVP.total_supply_cost,
    CASE 
        WHEN C.avg_order_value IS NULL THEN 'No Orders'
        ELSE 'Has Orders'
    END AS order_status
FROM 
    HighValueParts HVP
FULL OUTER JOIN 
    CustomerOrders C ON HVP.total_supply_cost > 1000 AND HVP.p_partkey = C.c_custkey
WHERE 
    (C.order_count IS NULL OR C.order_count >= 5)
ORDER BY 
    HVP.total_supply_cost DESC, 
    C.avg_order_value ASC;
