
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
),
SupplierPartDetails AS (
    SELECT 
        s.s_suppkey,
        p.p_partkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, p.p_partkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        SUM(spd.total_avail_qty * spd.avg_supply_cost) AS supplier_performance
    FROM 
        SupplierPartDetails spd
    JOIN 
        supplier s ON spd.s_suppkey = s.s_suppkey
    GROUP BY 
        s.s_suppkey
    HAVING 
        SUM(spd.total_avail_qty * spd.avg_supply_cost) > 10000
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    o.o_totalprice,
    COALESCE(s.s_name, 'Unknown Supplier') AS supplier_name,
    CASE 
        WHEN o.o_totalprice IS NULL THEN 'Price not available'
        WHEN o.o_totalprice > 1000 THEN 'High value order'
        ELSE 'Standard order'
    END AS order_value_category
FROM 
    RankedOrders o
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    o.o_orderkey IN (SELECT r.o_orderkey FROM RankedOrders r WHERE r.order_rank <= 10)
    AND (s.s_suppkey IS NULL OR s.s_suppkey IN (SELECT ts.s_suppkey FROM TopSuppliers ts))
ORDER BY 
    o.o_orderdate DESC, o.o_totalprice DESC
LIMIT 50;
