
WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value,
        COUNT(l.l_linenumber) AS line_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
),
NationRegions AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name
    FROM 
        nation n
    LEFT JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    ss.s_name,
    n.r_name,
    COALESCE(os.total_value, 0) AS order_total_value,
    ss.total_available,
    ss.avg_supply_cost,
    CASE 
        WHEN os.line_count IS NULL THEN 'No Orders'
        WHEN os.line_count > 5 THEN 'High Volume'
        ELSE 'Regular Volume'
    END AS order_category
FROM 
    SupplierStats ss
LEFT JOIN 
    OrderSummary os ON ss.s_suppkey = os.o_orderkey
LEFT JOIN 
    customer c ON c.c_custkey = os.o_orderkey
JOIN 
    NationRegions n ON c.c_nationkey = n.n_nationkey
WHERE 
    ss.total_available > 1000
ORDER BY 
    order_category DESC, order_total_value DESC;
