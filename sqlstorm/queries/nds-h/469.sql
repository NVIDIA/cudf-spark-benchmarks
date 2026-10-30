
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1998-01-01'
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, 
        ps.ps_suppkey
),
CustomerStats AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    RANK() OVER (PARTITION BY p.p_brand ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank,
    COALESCE(s.total_avail_qty, 0) AS available_quantity,
    cs.total_orders,
    cs.avg_order_value
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    SupplierParts s ON p.p_partkey = s.ps_partkey
LEFT JOIN 
    CustomerStats cs ON cs.total_orders > 0
WHERE 
    p.p_retailprice > 100.00
    AND p.p_container IN ('BOX', 'PLATE')
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand, s.total_avail_qty, cs.total_orders, cs.avg_order_value
HAVING 
    COUNT(l.l_orderkey) > 5
ORDER BY 
    revenue_rank DESC, available_quantity DESC;
