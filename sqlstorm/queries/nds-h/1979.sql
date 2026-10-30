WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= '1996-01-01' AND 
        o.o_orderdate < '1997-01-01'
),
SupplierPartInfo AS (
    SELECT 
        ps.ps_partkey,
        s.s_nationkey,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, s.s_nationkey
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        COALESCE(sp.total_supply_cost, 0) AS total_supply_cost
    FROM 
        part p
    LEFT JOIN 
        SupplierPartInfo sp ON p.p_partkey = sp.ps_partkey
),
CustomerOrderMetrics AS (
    SELECT 
        r.o_orderkey,
        p.p_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        COUNT(DISTINCT r.o_orderdate) AS order_count
    FROM 
        RankedOrders r
    JOIN 
        lineitem l ON r.o_orderkey = l.l_orderkey
    JOIN 
        PartDetails p ON l.l_partkey = p.p_partkey
    GROUP BY 
        r.o_orderkey, p.p_partkey
)
SELECT 
    cm.o_orderkey,
    d.p_name,
    d.p_brand,
    cm.revenue,
    cm.order_count,
    CASE 
        WHEN d.total_supply_cost IS NULL OR d.total_supply_cost = 0 THEN 'No Supplier'
        ELSE 'Supplier Exists'
    END AS Supplier_Status
FROM 
    CustomerOrderMetrics cm
JOIN 
    PartDetails d ON cm.p_partkey = d.p_partkey
WHERE 
    cm.revenue > 1000
ORDER BY 
    cm.revenue DESC
LIMIT 50;