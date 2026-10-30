
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank,
        COUNT(l.l_orderkey) OVER (PARTITION BY o.o_orderkey) AS total_items
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
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
        ps.ps_partkey, ps.ps_suppkey
    HAVING 
        SUM(ps.ps_availqty) > 100 
    AND 
        AVG(ps.ps_supplycost) < 50.00
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS num_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
    HAVING 
        COUNT(o.o_orderkey) > 5
)

SELECT 
    r.r_name,
    SUM(COALESCE(co.total_spent, 0)) AS total_customer_spending,
    COUNT(DISTINCT ro.o_orderkey) AS total_orders,
    AVG(sp.avg_supply_cost) AS avg_supplier_cost
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierParts sp ON sp.ps_suppkey = s.s_suppkey
LEFT JOIN 
    CustomerOrders co ON co.c_custkey = s.s_suppkey
LEFT JOIN 
    RankedOrders ro ON ro.o_orderstatus = 'F' AND ro.o_orderkey = co.num_orders
WHERE 
    r.r_name LIKE 'South%' 
    OR n.n_comment IS NULL
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT CASE WHEN sp.total_avail_qty IS NOT NULL THEN sp.ps_partkey END) > 10
ORDER BY 
    total_customer_spending DESC, total_orders ASC
LIMIT 50;
