
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_nationkey,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus = 'O'
),
SupplierPartDetails AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
LineItemSummary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        AVG(l.l_quantity) AS avg_quantity,
        COUNT(l.l_orderkey) AS order_count
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '1996-01-01' AND l.l_returnflag = 'N'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    r.r_name,
    COALESCE(SUM(l.total_revenue), 0) AS total_revenue,
    COALESCE(SUM(s.total_available), 0) AS total_available_parts,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(COALESCE(l.avg_quantity, 0)) AS average_quantity_sum,
    COUNT(DISTINCT CASE 
        WHEN s.total_cost > 10000 THEN s.s_suppkey 
    END) AS rich_suppliers_count
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    RankedOrders o ON c.c_custkey = o.o_orderkey
LEFT JOIN 
    LineItemSummary l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    SupplierPartDetails s ON s.s_suppkey = c.c_nationkey 
WHERE 
    r.r_name IS NOT NULL
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    total_revenue DESC;
