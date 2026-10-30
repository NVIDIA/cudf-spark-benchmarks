WITH SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        COUNT(DISTINCT l.l_linenumber) AS line_count,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS order_seq
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
CustomerRegion AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        n.n_name AS nation_name,
        r.r_name AS region_name
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    cr.c_name,
    cr.region_name,
    si.s_name,
    si.total_cost,
    od.net_revenue,
    od.line_count
FROM 
    CustomerRegion cr
LEFT JOIN 
    SupplierInfo si ON cr.c_custkey = si.s_nationkey
FULL OUTER JOIN 
    OrderDetails od ON cr.c_custkey = od.o_orderkey
WHERE 
    (si.total_cost IS NOT NULL OR od.net_revenue IS NOT NULL)
    AND (od.line_count > 1 OR si.total_cost > 1000.00)
ORDER BY 
    cr.region_name, cr.c_name;
