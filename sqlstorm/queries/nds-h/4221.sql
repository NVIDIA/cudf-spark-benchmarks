WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1997-01-01'
),
HighValueOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        COUNT(*) OVER (PARTITION BY ro.o_orderdate) AS total_orders
    FROM 
        RankedOrders ro
    WHERE 
        ro.order_rank <= 5
),
PartSupplierInfo AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(count(l.l_orderkey), 0) AS total_orders,
    COALESCE(AVG(l.l_extendedprice), 0) AS avg_extended_price,
    CASE 
        WHEN psi.total_supply_cost IS NULL THEN 'No Supply Info' 
        ELSE CONCAT('Total Supply Cost: ', psi.total_supply_cost)
    END AS supply_info,
    ROUND(AVG(ho.o_totalprice), 2) AS avg_high_value_order_price
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    PartSupplierInfo psi ON p.p_partkey = psi.ps_partkey
LEFT JOIN 
    HighValueOrders ho ON ho.o_orderkey = l.l_orderkey
GROUP BY 
    p.p_partkey, p.p_name, psi.total_supply_cost
ORDER BY 
    total_orders DESC, avg_extended_price DESC
LIMIT 10;